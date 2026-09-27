# Completion Report: e2-s1 REWORK — iOS package resolution and "no native iOS code"

Instruction: `10xs/workflow/instructions/20260927_07_e2-s1-rework-ios-resolution.md`
(commit `1b7e03d` on `develop`, the tip when this rework started).

## Work Completed

| File | Purpose |
|---|---|
| `packages/readiness_check/lib/src/pub_dev_client.dart` | `PackageInfo.platforms` now carries a `PluginPlatformInfo` per declared platform (`defaultPackage`, `pluginClass`, `ffiPlugin`, `declaresNativeImplementation`), not just a flattened `default_package` map. Parses `default_package`/`pluginClass` leniently (only accepts a `String`) after a live run hit a real pub.dev shape that isn't one: `flutter_soloud`'s `web` platform declares `"default_package": true`. |
| `packages/readiness_check/lib/src/ios_resolution.dart` (new) | `resolveIosPackage` (app-facing pubspec's `ios` entry wins in any form — `default_package` *or* inline `pluginClass`/`ffiPlugin` — falling back to `macos` then `darwin` only when `ios` is absent entirely) and `declaresNativeIos` (true when the resolved package's own entry for that platform declares `pluginClass`/`ffiPlugin`, or its archive ships a `.podspec` under `ios/`, `macos/` or `darwin/`). |
| `packages/readiness_check/lib/src/grading.dart` | `swiftPmStatus`/`swiftPmEvidence`: `nativeIos == false` grades green ("Not affected: no native iOS code"), ahead of the tag/archive rules. A `null` `nativeIos` (older snapshots, additive field) behaves exactly as before. |
| `packages/readiness_check/lib/src/snapshot_model.dart` | `SwiftPmInfo.nativeIos` (nullable `bool`, parsed from JSON). |
| `packages/snapshot_job/lib/src/plugin_snapshot.dart`, `snapshot_assembler.dart` | `_assembleOne` now resolves via `resolveIosPackage`, reuses the app-facing `PackageInfo` when the resolution isn't federated (no extra call) or fetches the resolved package's own info when it is (federated case), then computes `nativeIos` via `declaresNativeIos`. `SwiftPmSnapshot.nativeIos` (non-null `bool`) is written into the snapshot contract; `schemaVersion` stays 1. |
| Tests: `pub_dev_client_test.dart`, `snapshot_assembler_test.dart`, `site/test/grading_test.dart` | New coverage per the instruction's "Tests (offline)" section — see below. |

## Design Notes

- **Never fall back to macOS when iOS resolves.** The bug: the old code did
  `info?.defaultPackageFor('ios') ?? info?.defaultPackageFor('macos') ?? candidate.name`,
  which only recognizes `default_package`. `flutter_keyboard_visibility`
  declares iOS inline (`ios: {pluginClass: ...}`, no `default_package`), so
  `defaultPackageFor('ios')` was `null` and it fell through to
  `flutter_keyboard_visibility_macos`'s archive — a tag/archive disagreement
  that doesn't exist on the plugin's own archive. `resolveIosPackage` now
  checks for the platform *entry itself* (any form), not just its
  `default_package`, before ever considering `macos`.
- **`nativeIos` needs the *resolved* package's own declaration**, not the
  app-facing package's. For `path_provider` → `path_provider_foundation`,
  that's a different package's pubspec. Reusing the app-facing `PackageInfo`
  would be wrong (it doesn't carry `path_provider_foundation`'s own
  `dartPluginClass`-only entry). `_assembleOne` fetches the resolved
  package's own info only when federation actually moved the check to a
  different package — the common (non-federated) case adds no extra call.
- **Podspec check, not Package.swift.** Per the instruction, `nativeIos`
  looks for a `.podspec` (CocoaPods evidence), not a `Package.swift`
  (SwiftPM evidence) — the two are deliberately independent signals: a
  plugin can be `nativeIos: true` and still be fully SwiftPM-ready.
- **Lenient JSON parsing, matching the old code's own leniency.** The old
  `default_package`-only extraction used a `case final String x` pattern
  match, which silently skips a non-string value. My first version of
  `PluginPlatformInfo.fromJson` used an unchecked `as String?` cast instead,
  which crashed the live run on `flutter_soloud` (`"default_package": true`
  under its `web` platform — real, unrelated to this rework, but newly
  reachable because that platform's raw JSON is now parsed at all). Fixed to
  use the same "accept only `String`, else null" leniency as before.

## Automated Test Results

```
$ cd packages/readiness_check && dart analyze --fatal-infos   # No issues found!
$ dart test                                                    # 00:00 +46: All tests passed!
$ cd packages/snapshot_job && dart analyze --fatal-infos       # No issues found!
$ dart test                                                    # 00:00 +7: All tests passed!
$ cd site && dart analyze --fatal-infos                        # No issues found!
$ dart test                                                    # 00:00 +17: All tests passed!
$ cd packages/flutter_ready && dart analyze --fatal-infos      # No issues found!
$ dart test                                                    # 00:00 +17: All tests passed!
```

New tests added (all offline, per the instruction's "Tests (offline)"
section):
- `pub_dev_client_test.dart`: a `flutter_soloud`-shaped fixture (`pluginClass`
  + `ffiPlugin: true` on `ios`, `default_package: true` — a bool — on `web`)
  parses without throwing.
- `snapshot_assembler_test.dart`: a `path_provider` shape (federated to a
  `dartPluginClass`-only foundation package, no podspec) → `nativeIos: false`;
  a `flutter_keyboard_visibility` shape (inline iOS `pluginClass`, macOS
  `default_package`) → checks its own archive, `nativeIos: true`; the
  existing `url_launcher`/`some_plugin` cases updated to declare a realistic
  `pluginClass` and assert `nativeIos: true`.
- `site/test/grading_test.dart`: `nativeIos: false` grades green regardless
  of tag/archive; `nativeIos: true` doesn't suppress the existing red/amber
  rules; `nativeIos: null` (pre-existing snapshots) behaves unchanged.

## Live Run (fleetbox, foreground)

```
$ cd packages/snapshot_job && dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/
Assembled 100 plugin(s) from 100 candidate(s) in 0:00:11.777607.
```

- 100/100 candidates assembled, **0 plugins with a non-empty `errors` list**
  (the first attempt hit the `flutter_soloud` cast crash above, recorded as
  one plugin error; fixed, then re-run clean).
- Committed `data/snapshots/2026-09-27.json` and `data/latest.json`
  (`schemaVersion: 1`, `generatedAt: 2026-09-27T03:08:15.629380Z`, `topN: 100`).

**SwiftPM colour changes vs the 2026-09-26 snapshot** (9 plugins, all
red/amber → green, none the other direction):

| Plugin | Before | After | Why |
|---|---|---|---|
| `flutter_keyboard_visibility` | amber | green | Now checks its own archive (`Package.swift` present) instead of `flutter_keyboard_visibility_macos`'s. |
| `path_provider` | red | green ("not affected") | `path_provider_foundation` is `dartPluginClass`-only, no podspec — `nativeIos: false`. |
| `android_alarm_manager_plus`, `android_id`, `camera_android_camerax`, `flutter_overlay_window`, `flutter_plugin_android_lifecycle`, `smart_auth`, `youtube_player_iframe` | red | green ("not affected") | Android-only plugins with no iOS platform entry and no `.podspec` in their archive — `nativeIos: false`. Not named in the instruction but the same rule fixes them; this is the intended generalization, not scope creep. |

**Three plugins stay red** (`in_app_update`, `flutter_displaymode`,
`flutter_background`): each declares only an `android` platform in its
pubspec, but its archive still ships a real `ios/<name>.podspec` (a leftover
from plugin-template scaffolding). Per the instruction's own rule, a shipped
podspec is sufficient evidence of `nativeIos: true`, so these are unaffected
by this rework — they were red before and remain red now, on unchanged
reasoning. Flagged here for visibility, not treated as a new bug to fix
under this instruction.

## Build Verification

No production build step applies to library/CLI packages. `dart analyze
--fatal-infos` and `dart test` pass in all four packages (`readiness_check`,
`snapshot_job`, `site`, `flutter_ready`); the live run above is the
end-to-end verification for `snapshot_job`. `dart format` is clean on every
file this rework touched (pre-existing formatter drift in files I didn't
touch, e.g. in `packages/flutter_ready/test/`, is out of scope and left
alone).

## Known Issues / Limitations

- The three still-red plugins above ship a stray iOS podspec despite
  declaring no iOS platform support — arguably a separate false-red, but
  outside this instruction's named scope (`path_provider` and
  `flutter_keyboard_visibility` only). Left as a candidate for a future
  instruction if the owner wants it addressed.
- e6-2's golden CLI tests use fixture data under `fixtures/sample_app/data/`,
  not the live `data/` snapshots — unaffected by this rework, still passing.

## Suggested Commit Message

Already landed as four commits on `feature/e2-s1-rework-ios-resolution`:
`9773dd7`, `51d010f`, `1f39c68`, `98a15e6`.
