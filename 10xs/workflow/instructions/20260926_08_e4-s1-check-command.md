# Microtask Instruction: e4-s1 — check command

Written by the connected agent acting as architect, 2026-09-26, following
`00_ARCHITECT_GATE.md` and the e4-s1 section of
`20260927_05_architect-notes-e2-e6.md`.

## Objective

Add `flutter_ready check`: a CLI, run in an app repo, that reads
`pubspec.lock`, resolves each hosted package against the Flutter Ready
data, and reports per-deadline blockers with evidence (SPEC §3.3).

## Context

- `packages/readiness_check` already has the SwiftPM, alignment and Android
  checks and the pub.dev client (e1). `packages/snapshot_job` already
  assembles `data/latest.json` and `data/deadlines.json` (e2).
- The board's colour rules (`site/lib/data/grading.dart`, from e3-s1) grade
  a `PluginEntry` red/amber/green for SwiftPM and alignment, and treat
  Android as facts-only (SPEC open decision 3). The architect note requires
  the CLI use the *same* grading functions as the board, so they can't
  disagree (SPEC §2) — today those functions and their `PluginEntry`/
  `Snapshot` models live only in `site/lib/data/`, which the CLI can't
  depend on (it isn't a web app). They move to `readiness_check`, the
  package both already share.
- No `packages/flutter_ready` exists yet. The architect note fixes its
  shape: `bin/flutter_ready.dart check [--data <path|url>]`, default data
  source `https://raw.githubusercontent.com/Integrity-Ventures/flutter-ready/main/data/latest.json`.

## Implementation Steps

1. **Move the shared model and grading code into `readiness_check`**, so
   the board and the CLI use one implementation:
   - `packages/readiness_check/lib/src/snapshot_model.dart`: the
     `SwiftPmInfo`, `SoFile`, `AlignmentInfo`, `AndroidInfo`, `PluginEntry`,
     `Snapshot` and `Deadline` classes, moved from `site/lib/data/models.dart`
     (leave `DatedSnapshot` in `site`, since only the board's trend view
     needs it).
   - `packages/readiness_check/lib/src/grading.dart`: the `Status` enum and
     `swiftPmStatus`/`alignmentStatus`/`swiftPmEvidence`/`alignmentEvidence`/
     `isBlocked`/`swiftPmGreenSharePercent` functions, moved from
     `site/lib/data/grading.dart`, importing the new `snapshot_model.dart`.
   - Add both to `packages/readiness_check/lib/readiness_check.dart`'s
     exports.
   - Turn `site/lib/data/models.dart` and `site/lib/data/grading.dart` into
     thin `export 'package:readiness_check/readiness_check.dart' show ...;`
     files (`models.dart` keeps `DatedSnapshot`, defined locally, and adds
     the matching `import` so it can reference `Snapshot`). This keeps
     every existing relative import in `site/lib` and
     `site/test/grading_test.dart` working unchanged.
   - Add `readiness_check: {path: ../packages/readiness_check}` to
     `site/pubspec.yaml`. (`readiness_check` has no `dart:io` imports, so
     this is safe for the Jaspr client bundle too.)
2. **New package `packages/flutter_ready`**, laid out like `snapshot_job`:
   - `pubspec.yaml`: depends on `args`, `http`, `path`, `yaml`, and
     `readiness_check` by path. `publish_to: none` (e4-s3, publishing, is
     held).
   - `lib/src/pubspec_lock.dart`: `LockedPackage {name, version, isHosted}`
     and `parsePubspecLock(String contents)`, reading the lockfile's
     `packages:` map (`source: hosted` → `isHosted`).
   - `lib/src/check_report.dart`: pure (no IO) `buildCheckReport({
     lockedPackages, snapshot, deadlines}) -> CheckReport {text,
     hasBlocker}`. For each hosted locked package: if its name isn't in
     `snapshot.plugins`, or the versions differ, list it under "Not
     checked" — never green (SPEC §3.3). Otherwise, for each deadline whose
     `check` is `swiftpm` or `alignment`, grade it with the moved
     `swiftPmStatus`/`alignmentStatus`; a `Status.red` result is a blocker,
     grouped under that deadline's title, with the moved `*Evidence`
     string. Deadlines with `check: "android"` are skipped (facts only,
     open decision 3) — data-driven, so a future deadline needs no code
     change (SPEC open decision 6).
   - `lib/src/check_command.dart`: the `args` `Command` named `check`. Flags
     `--data` (default the raw GitHub URL above) and `--lockfile` (default
     `pubspec.lock`). Reads the lockfile from disk; reads the data JSON from
     an HTTP(S) URL or a local path; derives the deadlines source by
     replacing the data source's filename with `deadlines.json` in the same
     directory (works for both URL and path forms). Calls
     `buildCheckReport`, prints its `text`, and sets the process `exitCode`
     to 1 if `hasBlocker`, else 0.
   - `bin/flutter_ready.dart`: a `CommandRunner('flutter_ready', ...)`
     registering `CheckCommand`.
   - `lib/flutter_ready.dart`: barrel export of the two `src` files under
     `lib/src` needed by tests (`CheckReport`, `buildCheckReport`,
     `LockedPackage`, `parsePubspecLock`).
3. **Tests** (not counted against the file-count limit):
   - `packages/flutter_ready/test/pubspec_lock_test.dart`: hosted vs.
     git/path/sdk-sourced entries.
   - `packages/flutter_ready/test/check_report_test.dart`: a red SwiftPM
     blocker, a red alignment blocker, a version mismatch reported as "not
     checked" (never green), and a clean run with no blockers.
   - Leave `site/test/grading_test.dart` as-is; it must keep passing
     unchanged against the re-exported symbols.

## File Scope

- `packages/readiness_check/lib/src/snapshot_model.dart` (new)
- `packages/readiness_check/lib/src/grading.dart` (new)
- `packages/readiness_check/lib/readiness_check.dart`
- `site/lib/data/models.dart`, `site/lib/data/grading.dart`, `site/pubspec.yaml`
- `packages/flutter_ready/**` (new package: pubspec.yaml, analysis_options.yaml, bin/flutter_ready.dart, lib/flutter_ready.dart, lib/src/pubspec_lock.dart, lib/src/check_report.dart, lib/src/check_command.dart)
- `packages/flutter_ready/test/**` (new, tests)

## Acceptance Criteria

- `dart analyze --fatal-infos` and `dart test` pass, offline, in
  `packages/readiness_check`, `packages/flutter_ready` and `site`.
- A hosted package at the same version as a red-graded plugin in the data
  is reported as a blocker under the right deadline, with the same
  evidence text the board would show; `flutter_ready check` exits 1.
- A hosted package missing from the data, or at a different version, is
  reported as "not checked", never green; a run with no blockers exits 0.
- `site`'s board still builds against the same grading behaviour (existing
  `site/test/grading_test.dart` passes unchanged).

## Testing Strategy

Unit tests only (offline, no network) — no fixtures package yet (e6-s1 is
separate). Golden CLI report tests are e6-s2; this card's tests check
`buildCheckReport`'s decisions and `parsePubspecLock`'s parsing directly.
