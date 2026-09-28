# Microtask Instruction: make flutter_ready publishable as ONE package (OPEN)

Status: **OPEN.** Step 2 of card e4-s3 "Publish". The owner chose option (b)
on 2026-09-28: publish one self-contained package, `flutter_ready`, instead
of two. Read `00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST and stop if
the claim fails.

**NEVER run `dart pub publish` without `--dry-run`.** The owner publishes
the first version by hand from the hireflutter.dev admin account. A
published version can't be deleted.

## Why

pub.dev refuses a package with a `path:` dependency. `packages/flutter_ready`
depends on `packages/readiness_check` by path, and `readiness_check` isn't
on pub.dev. The owner doesn't want a second package to maintain.

## Fix: move (don't copy) readiness_check into flutter_ready

`readiness_check` is shared by three users: `packages/flutter_ready` (the
CLI), `packages/snapshot_job` (the nightly job) and `site/` (the board).
They must keep ONE copy of the grading rules, so:

1. Move `packages/readiness_check/lib/src/*` into
   `packages/flutter_ready/lib/src/` (a subfolder such as
   `lib/src/readiness/` is fine), and its public library file to
   `packages/flutter_ready/lib/readiness_check.dart` with the same exports.
   Use `git mv` so history follows. Move its tests and `test/fixtures/` into
   `packages/flutter_ready/test/`. Move its dependencies (`archive`, `http`)
   into flutter_ready's pubspec. Delete `packages/readiness_check/`.
2. Point every importer at the new home:
   `package:readiness_check/readiness_check.dart` becomes
   `package:flutter_ready/readiness_check.dart` in flutter_ready,
   snapshot_job and site. `snapshot_job` and `site` depend on
   `flutter_ready` by path (they are never published, so a path dependency
   is fine there). Fix `live_check_test.dart`'s fixtures path.
3. The site must still build: `site/` must not pull in anything `dart:io`-only
   that it didn't pull in before. If the move makes the site import CLI
   code, keep the CLI's `dart:io` parts out of `lib/readiness_check.dart`.
4. Update `.github/workflows/nightly-snapshot.yml` (it runs `dart pub get -C
   packages/readiness_check`) and any other path that names the old package
   (`git grep readiness_check`). `ci.yml` loops over `packages/*/` and needs
   no change. Update STATUS.md's package table.

## Make the package pub.dev-ready

In `packages/flutter_ready/`:
- Remove `publish_to: none` (only here; snapshot_job and site keep it).
- Keep `version: 0.1.0`, `homepage`, `repository`. Add
  `issue_tracker: https://github.com/Integrity-Ventures/flutter-ready/issues`.
  The description stays 60-180 characters.
- Add `README.md` (what it checks: SwiftPM before CocoaPods goes read-only
  on 2 December 2026, and 16 KB alignment for Play; install with
  `dart pub global activate flutter_ready`; usage of `flutter_ready check`,
  `--offline`, exit code 1 on a blocker; a link to https://ready.hireflutter.dev),
  `CHANGELOG.md` (`## 0.1.0` - first release) and a copy of the repo's MIT
  `LICENSE`.

## Tests and check

- `dart analyze --fatal-infos` and `dart test` pass in flutter_ready,
  snapshot_job and site. Test totals: nothing lost (before: flutter_ready 26
  + readiness_check 70 = 96 in the new flutter_ready).
- `cd site && jaspr build` passes, and the built `/` shows the same tile
  counts as before (83 Blocked, 8 Unclear, 45 Ready, 9 Not affected).
- `cd packages/snapshot_job && dart run bin/snapshot.dart` (or the command
  the nightly workflow runs) still works: run it once in the FOREGROUND and
  confirm the data shape is unchanged (don't commit new data unless it
  differs only in timestamps).
- `cd packages/flutter_ready && dart pub publish --dry-run` finishes with
  **0 warnings**. Quote its full output in the report.
- Install test, as a stranger would:
  `dart pub global activate --source path packages/flutter_ready`, then
  run `flutter_ready check` on a real app's `pubspec.lock` (for example
  one under `fixtures/`) and quote the output and exit code.
- Optional, if it installs cleanly: run `pana` on the package and report the
  pub points it predicts.
- Lane branch `feature/publish-prep`, pushed to your clone's origin; report
  at `10xs/workflow/task_reports/publish-prep_report.md`.
