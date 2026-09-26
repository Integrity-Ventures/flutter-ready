# Completion Report: e2-s1 — Snapshot assembly

Instruction: `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md`
(section "e2-s1: Snapshot assembly"). Continues WIP commit `4cbc483` on
`feature/e2-s1-snapshot-assembly` (saved by the architect after a prior seat's
background live run died with its turn — see `00_ARCHITECT_GATE.md`).

## Work Completed

Adds the `snapshot_job` package (a Dart CLI, `bin/snapshot.dart`) that
assembles one dated readiness snapshot per the architect's schemaVersion 1
contract, and extends `readiness_check`'s `PubDevClient` with the calls the
job needs (package info, archive URL, archive bytes).

| File | Lines | Purpose |
|---|---|---|
| `packages/readiness_check/lib/src/pub_dev_client.dart` | 146 (+79) | Adds `fetchLatestArchiveUrl`, `fetchArchiveBytes`, `fetchPackageInfo` + `PackageInfo` (version, publish date, per-platform federated `default_package`) |
| `packages/readiness_check/lib/readiness_check.dart` | 19 (+1) | Exports `PackageInfo` |
| `packages/readiness_check/test/pub_dev_client_test.dart` | 118 | Offline `MockClient` tests for the new client methods, including a federated-platforms case |
| `packages/snapshot_job/pubspec.yaml` | 21 | New package: depends on `readiness_check` by path, `args`, `http`, `path` |
| `packages/snapshot_job/analysis_options.yaml` | 1 | `package:lints/recommended.yaml` |
| `packages/snapshot_job/lib/snapshot_job.dart` | 8 | Public exports |
| `packages/snapshot_job/lib/src/concurrency_pool.dart` | 21 | `mapWithConcurrency` — bounded-parallelism map preserving input order |
| `packages/snapshot_job/lib/src/plugin_snapshot.dart` | 122 | `PluginSnapshot`/`SwiftPmSnapshot`/`AlignmentSnapshot`/`AndroidSnapshot` + `buildSnapshotJson`, matching the architect's schemaVersion 1 shape field-for-field |
| `packages/snapshot_job/lib/src/snapshot_assembler.dart` | 147 | `assembleSnapshot`: per-plugin score/info/archive fetch, federated-package resolution, per-plugin error isolation |
| `packages/snapshot_job/bin/snapshot.dart` | 79 | CLI entry point: `--top`, `--out`, descriptive User-Agent, writes dated file + `latest.json` |
| `packages/snapshot_job/test/snapshot_assembler_test.dart` | 301 | Offline tests: federated case, non-federated case (single archive fetch shared), two failure-isolation cases, contract-shape test |

All implementation files are within the 150-line stop-and-refactor limit
(largest is `snapshot_assembler.dart` at 147).

## Design Notes

- **Federated plugins** (review finding on e1-s2): `_assembleOne` resolves
  `iosPackage`/`androidPackage` from `PackageInfo.defaultPackageFor(...)`
  before running any archive check, falling back to the plugin's own name
  when unfederated. The `is:swiftpm-plugin` tag stays keyed to the app-facing
  package (per the architect's decision) — only the archive lookup moves to
  the resolved package. An `archiveCache` keyed by package name means a
  non-federated plugin (`iosPackage == androidPackage`) fetches its archive
  once, not twice.
- **Per-plugin failure isolation:** `_safeCall` wraps every network call
  (score, info, each archive) and records failures into that plugin's
  `errors` list instead of throwing — one plugin's 404 or malformed response
  never aborts the run. Fields whose fetch failed are left `null`, never
  omitted, so every plugin document has the same shape (architect contract).
- **Concurrency:** `mapWithConcurrency` runs a fixed pool of 4 workers
  pulling from a shared index, so exactly `concurrency` requests are in
  flight regardless of how unevenly individual plugins' checks take —
  simpler than chunking and keeps output order stable for a deterministic
  diff between runs.
- **Schema fidelity:** `plugin_snapshot.dart`'s `toJson()` methods were
  written directly against the architect's example JSON (field names,
  nesting, `null` for absent) rather than deriving a shape from the readiness
  types, so a mismatch would show up as a test failure in
  `buildSnapshotJson matches the schemaVersion 1 contract shape` rather than
  a silent drift.
- The CLI sends the architect-specified User-Agent on every request via a
  `http.BaseClient` wrapper, and defaults `--top` to 100 and `--out` to
  `data/snapshots/`, writing `data/latest.json` as a sibling of the snapshots
  directory.

## Automated Test Results

```
$ cd packages/readiness_check && dart analyze --fatal-infos
Analyzing readiness_check...
No issues found!

$ dart test
00:00 +36: All tests passed!

$ cd packages/snapshot_job && dart analyze --fatal-infos
Analyzing snapshot_job...
No issues found!

$ dart test
00:00 +5: All tests passed!
```

`dart format --output=none --set-exit-if-changed` on both packages: 19 files
formatted, 0 changed (exit 0).

All tests run offline against `MockClient`/hand-built bytes; zero network
calls in the test suite.

## Live Run (fleetbox, foreground)

```
$ cd packages/snapshot_job && dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/
Assembled 100 plugin(s) from 100 candidate(s) in 0:02:00.567901.

real    2m16.560s
```

- 100/100 candidates assembled, **0 plugins with a non-empty `errors` list**.
- Output committed: `data/snapshots/2026-09-26.json` and `data/latest.json`
  (`schemaVersion: 1`, `generatedAt: 2026-09-26T19:45:28.375457Z`, `topN: 100`).
- Spot-checked `url_launcher` (federated: `checkedPackage` resolves to
  `url_launcher_ios` / `url_launcher_android`, `swiftpm.agrees: true`),
  `shared_preferences` (federated to `shared_preferences_foundation` /
  `shared_preferences_android`) and `firebase_core` (unfederated, checks its
  own archive) — all match the expected shape and federation behaviour.

## Build Verification

No production build step applies to library/CLI packages. `dart analyze
--fatal-infos` (exit 0 on both packages) and `dart format` (no diff) both
pass; the live CLI run above is the end-to-end build/run verification for
`snapshot_job`.

## Known Issues / Limitations

- Some plugins' `android.compileSdk`/`agp` values are the plugin's raw Gradle
  text (e.g. `"flutter.compileSdkVersion"`, `"project.ext.compileSdk"`)
  rather than a resolved number — this is e1-s4's documented behaviour
  (values are recorded verbatim, SPEC open decision 3 is still unsettled),
  not something e2-s1 changes.
- The live run above is a single point-in-time sample, not a scheduled job —
  wiring it to run nightly and commit automatically is e2-s2's scope.

## Suggested Commit Message

```
Add snapshot_job package: nightly readiness snapshot assembly

Assembles one dated JSON snapshot per the architect's schemaVersion 1
contract, resolving federated plugins' iOS/Android archives via
PackageInfo.defaultPackageFor and isolating per-plugin failures into
that plugin's errors list. Includes a live --top 100 run committed as
data/snapshots/2026-09-26.json and data/latest.json.

Co-Authored-By: 10xs.ai
```
