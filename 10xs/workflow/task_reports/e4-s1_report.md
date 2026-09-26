# Completion Report: e4-s1 — check command

Instruction: `10xs/workflow/instructions/20260926_08_e4-s1-check-command.md`.

## Work Completed

### Shared grading moved into `readiness_check` (so board and CLI can't disagree, SPEC §2)

- `packages/readiness_check/lib/src/snapshot_model.dart` (new, 122 lines):
  `SwiftPmInfo`, `SoFile`, `AlignmentInfo`, `AndroidInfo`, `PluginEntry`,
  `Snapshot`, `Deadline` — moved from `site/lib/data/models.dart` verbatim
  (`DatedSnapshot` stayed in `site`; only the board's trend view needs it).
- `packages/readiness_check/lib/src/grading.dart` (new, 67 lines): `Status`
  enum and `swiftPmStatus`/`alignmentStatus`/`swiftPmEvidence`/
  `alignmentEvidence`/`isBlocked`/`swiftPmGreenSharePercent` — moved from
  `site/lib/data/grading.dart`, now importing `snapshot_model.dart`.
- `packages/readiness_check/lib/readiness_check.dart`: exports both.
- `site/lib/data/models.dart` and `site/lib/data/grading.dart`: now thin
  `export 'package:readiness_check/readiness_check.dart' show ...;` files
  (`models.dart` also keeps `DatedSnapshot`, defined locally). Every
  existing relative import across `site/lib` and `site/test` keeps
  working unchanged.
- `site/pubspec.yaml`: added `readiness_check` as a path dependency, and
  `publish_to: none` (needed once a path dependency is present;
  `dart analyze --fatal-infos` flagged this — see Known Issues).

### New package `packages/flutter_ready`

- `pubspec.yaml`, `analysis_options.yaml`: laid out like `snapshot_job`;
  depends on `args`, `http`, `path`, `yaml`, `readiness_check` (path).
  `publish_to: none` — e4-s3 (pub.dev publish) is held.
- `lib/src/pubspec_lock.dart` (27 lines): `LockedPackage` and
  `parsePubspecLock`, reading a lockfile's `packages:` map; `source:
  hosted` → `isHosted`.
- `lib/src/check_report.dart` (78 lines): pure (no IO) `buildCheckReport`.
  For each hosted locked package: missing from the data, or at a
  different version → "Not checked", never green (SPEC §3.3). Otherwise,
  for each deadline whose `check` is `swiftpm` or `alignment`, grades it
  with the moved functions; a `Status.red` result is a blocker, grouped
  under the deadline's title with the moved evidence string. A deadline
  with `check: "android"` is skipped (facts only, SPEC open decision 3) —
  driven entirely by `deadlines.json`, so a future deadline needs no code
  change (SPEC open decision 6).
- `lib/src/check_command.dart` (74 lines): the `check` `Command`. Flags
  `--data` (default
  `https://raw.githubusercontent.com/Integrity-Ventures/flutter-ready/main/data/latest.json`)
  and `--lockfile` (default `pubspec.lock`). Reads the lockfile from disk;
  reads the data JSON from an HTTP(S) URL or a local path; derives the
  deadlines source by replacing the data source's filename with
  `deadlines.json` in the same directory (works for both URL and local
  path forms). Sets `exitCode` to 1 if any blocker, else 0 (SPEC §3.3:
  "exits non-zero when a blocker is found").
- `bin/flutter_ready.dart` (18 lines): `CommandRunner` registering
  `CheckCommand`.
- `lib/flutter_ready.dart` (3 lines): barrel export for tests.

## Automated Test Results

```
$ (cd packages/readiness_check && dart analyze --fatal-infos && dart test)
No issues found!
... 36 tests, All tests passed!

$ (cd packages/flutter_ready && dart analyze --fatal-infos && dart test -j1)
No issues found!
... 8 tests (2 pubspec_lock_test, 6 check_report_test), All tests passed!

$ (cd site && dart analyze --fatal-infos && dart test -j1)
No issues found!
... 14 tests (grading_test.dart, unchanged), All tests passed!
```

`packages/flutter_ready/test/check_report_test.dart` covers: a red SwiftPM
blocker, a red alignment blocker, a version mismatch ("not checked"), a
plugin missing from the data ("not checked"), a clean run (no blockers,
exit 0), and a git-sourced dependency being ignored.
`packages/flutter_ready/test/pubspec_lock_test.dart` covers hosted/git/path
sources and an empty lockfile.

## Manual End-to-End Verification

Ran the built CLI against the repo's real `data/latest.json` (no network
needed — `--data` accepts a local path) with a hand-written
`pubspec.lock`:

```
$ dart run bin/flutter_ready.dart check --data ../../data/latest.json --lockfile /tmp/test_pubspec.lock

Flutter Ready check — 5 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: path_provider 2.1.6: No Package.swift in the path_provider_foundation archive.

Not checked:
  some_unknown_pkg 1.0.0: not in Flutter Ready's data.
  url_launcher_old 0.1.0: not in Flutter Ready's data.
$ echo $?
1
```

(`path_provider` 2.1.6 in the real data has `swiftpm: {tag: false, archive:
false}` → red, correctly flagged. The git-sourced dependency in the same
lockfile was silently skipped, as intended.) A second run with only
`url_launcher` (fully green in the data) printed "No blockers found." and
exited 0.

## Build Verification

`dart pub get` succeeded in all three touched packages (`readiness_check`,
`flutter_ready`, `site`); `dart analyze --fatal-infos` is clean in all
three.

## Known Issues / Limitations

- `jaspr build` in `site` fails on this fleetbox with "Found Dart
  executable ... but failed to verify the surrounding Dart SDK" —
  reproduced identically on `develop` HEAD (`bbbde39`) with none of this
  card's changes applied (verified via `git stash`), so it predates this
  card and isn't caused by it. `dart analyze` and `dart test` for `site`
  both pass; only the Jaspr web-asset build daemon is affected. Flagging
  for the architect/owner, not fixing here — out of this card's scope.
- No replacement-suggestion lookup: `data/replacements.json` doesn't exist
  yet (e4-s2). The report never mentions suggestions, per SPEC §3.3
  ("where one is known") and the card split.
- No fixtures package yet (e6-s1) and no golden CLI tests yet (e6-s2); this
  card's tests are unit tests against `buildCheckReport` and
  `parsePubspecLock` directly, as scoped in the instruction file.

## Suggested Commit Message

```
Add flutter_ready CLI check command (e4-s1)

Co-Authored-By: 10xs.ai
```
