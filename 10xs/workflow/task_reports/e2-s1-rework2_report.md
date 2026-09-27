# Completion Report: e2-s1 REWORK 2 — Android-only plugins are not iOS plugins

Instruction: `10xs/workflow/instructions/20260927_11_e2-s1-rework-android-only.md`
(commit `7ccebbe` on `develop`, the tip when this rework started).

## Work Completed

| File | Purpose |
|---|---|
| `packages/readiness_check/lib/src/ios_resolution.dart` | New `NativeIosResult` (`nativeIos`, `reason`) and `resolveNativeIos(appInfo, resolution, resolvedInfo, archiveEntryPaths)`. When the app-facing pubspec (`appInfo`) declares neither an `ios` nor a `macos` platform entry, returns `nativeIos: false, reason: 'not-ios-plugin'` **without calling `declaresNativeIos`** — the archive's `ios/` folder is never consulted. Otherwise delegates to the existing `declaresNativeIos` and sets `reason: 'no-native-ios-code'` only when that comes back false. `declaresNativeIos` itself is unchanged. |
| `packages/readiness_check/lib/src/snapshot_model.dart` | `SwiftPmInfo.reason` (nullable `String`, parsed from JSON): set only when `nativeIos` is false. |
| `packages/readiness_check/lib/src/grading.dart` | `swiftPmEvidence`: when `nativeIos == false`, branches on `reason` — `'not-ios-plugin'` → "Not affected: not an iOS plugin.", anything else (including the pre-existing `null`) → "Not affected: no native iOS code." `swiftPmStatus` is unchanged (both reasons already grade green via the existing `nativeIos == false` check). |
| `packages/snapshot_job/lib/src/plugin_snapshot.dart` | `SwiftPmSnapshot.reason` (nullable `String`), written into the snapshot contract's `swiftpm.reason`. `schemaVersion` stays 1 (additive field, same pattern as `nativeIos` from rework 1). |
| `packages/snapshot_job/lib/src/snapshot_assembler.dart` | `_assembleSwiftPm` now takes the app-facing `PackageInfo?` (`info`, already fetched in `_assembleOne`) and calls `resolveNativeIos` instead of `declaresNativeIos` directly. |
| `packages/readiness_check/lib/readiness_check.dart` | Exports `NativeIosResult` and `resolveNativeIos`. |
| Tests: `packages/snapshot_job/test/snapshot_assembler_test.dart`, `site/test/grading_test.dart` | New coverage per the instruction's "Tests (offline)" section — see below. |

## Design Notes

- **Two independent reasons for `nativeIos: false`.** Rework 1 introduced a
  single boolean with one implicit reason ("no native iOS code" — a
  `dartPluginClass`-only federated package). This rework adds a second,
  distinct reason for a different root cause: the plugin never declares an
  iOS/macOS platform in its own pubspec at all, so Flutter's tooling never
  looks at its `ios/` folder regardless of what's in the archive. Grading
  (`swiftPmStatus`) treats both the same (green); only the evidence text
  (`swiftPmEvidence`) distinguishes them, per the instruction.
- **`not-ios-plugin` short-circuits before any archive check**, per the
  instruction's "Don't look at the archive's `ios/` folder in that case."
  This is why `resolveNativeIos` checks `appInfo` first and returns early —
  `declaresNativeIos` (which does the podspec-dir scan) is never invoked for
  an Android-only plugin, so its stray `ios/<name>.podspec` is structurally
  unreachable, not just unlucky to not match.
- **Checked against `appInfo` (the app-facing package), not `resolvedInfo`
  (the resolved package).** For an Android-only, non-federated plugin the two
  are the same object; the distinction only matters for a hypothetical
  federated Android-only plugin, where the app-facing pubspec is still the
  authority on which platforms the plugin declares to Flutter's tooling.
- **`reason` is `null` whenever `nativeIos` is `true`**, and also `null` for
  snapshots taken before this field existed (parses to `null` from missing
  JSON) — grading already treats a missing/null `reason` as the pre-existing
  "no native iOS code" text, so old snapshots render unchanged.

## Automated Test Results

```
$ cd packages/readiness_check && dart analyze --fatal-infos   # No issues found!
$ dart test                                                    # 00:00 +46: All tests passed!
$ cd packages/snapshot_job && dart analyze --fatal-infos       # No issues found!
$ dart test                                                    # 00:00 +8: All tests passed!
$ cd site && dart analyze --fatal-infos                        # No issues found!
$ dart test                                                    # 00:00 +18: All tests passed!
$ cd packages/flutter_ready && dart analyze --fatal-infos      # No issues found!
$ dart test                                                    # 00:00 +17: All tests passed!
```

New/changed tests, all offline, per the instruction's "Tests (offline)"
section:
- `snapshot_assembler_test.dart`: a new `in_app_update`-shaped fixture
  (pubspec declares only `android`, archive ships a stray
  `ios/in_app_update.podspec`) → `nativeIos: false, reason: 'not-ios-plugin'`.
  The existing `path_provider` case now also asserts
  `reason: 'no-native-ios-code'`. The existing `flutter_keyboard_visibility`
  case (declares `ios` inline) is unaffected and still passes.
- `site/test/grading_test.dart`: a new case asserts `reason: 'not-ios-plugin'`
  grades green with evidence text "Not affected: not an iOS plugin.". The
  existing `nativeIos: false` case is updated to also pass
  `reason: 'no-native-ios-code'` and still expects "Not affected: no native
  iOS code."; the `nativeIos: true` and `nativeIos: null` cases are
  unchanged and still pass.

## Live Run (fleetbox, foreground)

```
$ cd packages/snapshot_job && dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/
Assembled 100 plugin(s) from 100 candidate(s) in 0:01:47.684845.
```

- 100/100 candidates assembled, **0 plugins with a non-empty `errors` list**.
- Committed `data/snapshots/2026-09-27.json` and `data/latest.json`
  (`schemaVersion: 1`, `generatedAt: 2026-09-27T04:21:58.657173Z`, `topN: 100`),
  overwriting the same-UTC-date file from rework 1's run earlier today.

**SwiftPM colour changes vs. rework 1's 2026-09-27 run** (the named scope of
this instruction):

| Plugin | Before | After | Why |
|---|---|---|---|
| `in_app_update` | red | green | Pubspec declares only `android`; the archive's `ios/in_app_update.podspec` is now never consulted. Evidence: "Not affected: not an iOS plugin." |
| `flutter_displaymode` | red | green | Same shape. |
| `flutter_background` | red | green | Same shape. |

**No plugin is red in this run.** (`android_alarm_manager_plus`, `android_id`,
`camera_android_camerax`, `flutter_overlay_window`,
`flutter_plugin_android_lifecycle`, `smart_auth`, `youtube_player_iframe` were
already green from rework 1's generalized `no-native-ios-code` fix — this
run's diff against rework 1's own output touches only the three named
plugins, confirmed by comparing snapshot-to-snapshot.)

## Build Verification

No production build step applies to library/CLI packages. `dart analyze
--fatal-infos` and `dart test` pass in all four packages (`readiness_check`,
`snapshot_job`, `site`, `flutter_ready`); the live run above is the
end-to-end verification for `snapshot_job`. `dart format` is clean on every
file this rework touched (one file, `snapshot_assembler.dart`, needed
`dart format` applied after the initial edit — committed already formatted).

## Known Issues / Limitations

- None found against this instruction's named scope. The board now shows
  zero red SwiftPM rows in the top 100 — worth flagging to the owner as a
  fact (not a defect): the CocoaPods-readiness signal currently has no red
  examples to show a visitor what a blocker looks like. Out of scope for
  this instruction to address.

## Suggested Commit Message

Already landed as two commits on `feature/e2-s1-rework-android-only`:
`1d506ee` (code + tests), `3abb970` (regenerated data).
