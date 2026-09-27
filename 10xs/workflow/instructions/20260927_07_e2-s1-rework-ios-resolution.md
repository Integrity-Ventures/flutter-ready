# Microtask Instruction: e2-s1 REWORK — iOS package resolution and "no native iOS code" (DONE)

Status: **DONE.** Commit `3de27e365dd678db2fd81eb8aec44b2ed9046fec` on
`feature/e2-s1-rework-ios-resolution` (pushed to the local origin). Report:
`10xs/workflow/task_reports/e2-s1-rework_report.md`. Originally written by
the architect on 2026-09-27 after reviewing the first board build (e3-s1,
screenshots in `10xs/workflow/evidence/`).

## Objective

Remove two false results from the snapshot (and therefore from the board and
the CLI).

## Findings (measured on pub.dev 2026-09-27 from the fleetbox)

1. **False red: `path_provider`.** Its iOS `default_package` is
   `path_provider_foundation` 2.6.0, whose pubspec declares only
   `dartPluginClass` for ios/macos, with no `pluginClass` and no `ffiPlugin`.
   Its archive has no `Package.swift` and no native iOS sources. A plugin
   with no native iOS code has nothing to migrate off CocoaPods, so the
   CocoaPods deadline can't block it. The snapshot records
   `{"tag":false,"archive":false}`, and the board shows it red ("Blocked").
2. **False amber: `flutter_keyboard_visibility`.** Its pubspec has
   `ios: {pluginClass: …}` (inline iOS implementation) and
   `macos: {default_package: flutter_keyboard_visibility_macos}`. The job
   checked `flutter_keyboard_visibility_macos` (the macOS package) instead
   of the plugin's own archive, which does contain
   `ios/flutter_keyboard_visibility/Package.swift`. So it records a tag and
   archive disagreement that doesn't exist.

## Implementation Steps

1. `packages/snapshot_job` (and readiness_check where the logic belongs), to
   resolve the package that carries the iOS implementation:
   - Read `platforms.ios` of the app-facing pubspec. If it has
     `default_package`, the iOS package is that package. If it has
     `pluginClass` or `ffiPlugin: true`, the iOS package is the plugin
     itself. If there's no `ios` entry, use the same rule for `macos`, then
     `darwin`-shared packages. Never pick macOS when iOS resolves.
   - Record the result in `swiftpm.checkedPackage`, as now.
2. Add a field `swiftpm.nativeIos` (bool). It's true when the resolved iOS
   package declares `pluginClass` or `ffiPlugin: true` for ios (or macos when
   iOS is absent), OR its archive contains a `.podspec` under `ios/`,
   `macos/` or `darwin/`. It's false when the package declares only
   `dartPluginClass` and ships no podspec. Keep `schemaVersion` 1; the field
   is additive.
3. Grading. Put it in `packages/readiness_check` as a shared function so the
   CLI (e4-s1) reuses it, and switch `site/lib/data/grading.dart` to call it
   (keep `site` tests passing):
   - `nativeIos == false`: green, "Not affected: no native iOS code".
   - Otherwise keep the existing rules (both ready: green; disagree: amber;
     both not ready: red).
4. Regenerate the live data in the FOREGROUND: `--top 100`, committing
   `data/snapshots/<UTC date>.json` and `data/latest.json`. In your report,
   list every plugin whose SwiftPM colour changed versus the 2026-09-26
   snapshot.

## Tests (offline)

- A `path_provider` shape (app-facing package plus a `dartPluginClass`-only
  foundation package with no podspec) grades green "not affected".
- A `flutter_keyboard_visibility` shape (inline iOS `pluginClass` plus a
  macOS `default_package`) checks the plugin's own archive and agrees.
- The existing federated `url_launcher` shape still checks `url_launcher_ios`.

## File Scope

- `packages/snapshot_job/**`
- `packages/readiness_check/lib/**` and `test/**` (resolution and grading helpers)
- `site/lib/data/grading.dart`, `site/test/**`
- `data/snapshots/<date>.json`, `data/latest.json`

## Acceptance Criteria

- `path_provider` is green (not affected) in the new snapshot's grading;
  `flutter_keyboard_visibility` is green or red on its own archive, not amber.
- `dart analyze --fatal-infos` and `dart test` pass in readiness_check,
  snapshot_job and site.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground runs, a lane
  branch `feature/e2-s1-rework-ios-resolution` pushed to the local origin,
  and a report at `10xs/workflow/task_reports/e2-s1-rework_report.md`. Then
  set this file's Status line to DONE with the commit sha.
