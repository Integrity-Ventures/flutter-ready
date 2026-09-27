# Microtask Instruction: e2-s1 REWORK 2 — Android-only plugins are not iOS plugins (OPEN, not done)

Status: **OPEN.** Written by the architect on 2026-09-27; the owner approved
this third run of e2-s1. A worker launched on card e2-s1 executes THIS file.

## Finding (measured on pub.dev 2026-09-27)

The 2026-09-27 snapshot shows 3 reds: `in_app_update` 5.0.0,
`flutter_displaymode` 0.7.0 and `flutter_background` 1.3.1. For all three:

- the pubspec `flutter.plugin.platforms` declares **only `android`**;
- the pub.dev score tags carry **only `platform:android`**;
- the archive still ships an `ios/` folder with a `.podspec`, left over
  from `flutter create --template=plugin`.

Flutter registers pods only for platforms the pubspec declares, so an iOS
app never installs these pods. They can't be blocked by CocoaPods going
read-only, so these are false reds.

## Change

1. When the app-facing pubspec's `flutter.plugin.platforms` declares neither
   `ios` nor `macos`, set `swiftpm.nativeIos = false` and record
   `swiftpm.reason = "not-ios-plugin"`. Don't look at the archive's `ios/`
   folder in that case. Keep the existing `nativeIos=false` path for
   dartPluginClass-only packages, with `reason = "no-native-ios-code"`.
2. Grading in `packages/readiness_check` shows green with these texts:
   - `not-ios-plugin`: "Not affected: not an iOS plugin"
   - `no-native-ios-code`: "Not affected: no native iOS code" (as today)
   The site and CLI keep using the shared grading.
3. Tests (offline): an Android-only plugin with a stray `ios/*.podspec`
   grades green "not an iOS plugin"; the existing path_provider and
   flutter_keyboard_visibility cases keep passing.
4. Regenerate the live data in the FOREGROUND (`--top 100`), committing
   `data/snapshots/<UTC date>.json` and `data/latest.json`. List every
   plugin whose colour changed, and every plugin that's still red with its
   evidence.

## Acceptance

- The 3 plugins above are green "not an iOS plugin" in the new snapshot.
- `dart analyze --fatal-infos` and `dart test` pass in all four packages.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground, lane branch
  `feature/e2-s1-rework-android-only`, and a report at
  `10xs/workflow/task_reports/e2-s1-rework2_report.md`.
