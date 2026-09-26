# Completion Report: e1-s1 REWORK — plugin filter and top-N

Instruction: `10xs/workflow/instructions/20260927_03_e1-s1-rework.md`

## Work Completed

| File | Change |
|---|---|
| `packages/readiness_check/lib/src/plugin_discovery.dart` | `_isFlutterPlugin` now also requires `is:plugin`. `discoverFlutterPlugins` walks the ranked list in order, fetches tags one name at a time, and stops once `topN` plugins have been *kept* (or the ranked list runs out) — `topN` now counts post-filter plugins, not raw names. Doc comment rewritten to match. |
| `packages/readiness_check/test/plugin_discovery_test.dart` | Added `is:plugin` to the `url_launcher` fixture; added `shared_preferences` (a second real plugin, `is:plugin` + both mobile platform tags) and `provider` (the pure-Dart false-positive case: `sdk:flutter` + both platform tags, no `is:plugin`). Renamed/rewrote the filter test to assert `provider` is dropped. Replaced "applies topN to the raw list before filtering" with "counts topN after filtering and stops fetching once N are found", which asserts both the returned name and that the mock's score endpoint was never hit for the plugin past the Nth match. |
| `SPEC.md` §3.1.1 | Added the `is:plugin` requirement to the filter sentence and a dated note: "(added 2026-09-27, acting PM for the owner: pure-Dart packages such as provider and flutter_map carry the platform tags too; url_launcher and shared_preferences carry is:plugin)". Added a sentence stating N is counted after the filter. |

All implementation files remain well under the 150-line stop-and-refactor limit (`plugin_discovery.dart` is 46 lines).

## Why (carried from the instruction)

The first pass (merged at `7b4ef02`) applied `topN` to the raw ranked name
list before filtering, so `topN: 100` could yield far fewer than 100 plugins,
contrary to SPEC §3.1.1's "top N Flutter plugins." It also lacked the
`is:plugin` tag in its filter, so pure-Dart Flutter packages that carry every
platform tag (`provider`, `flutter_map`, confirmed live against pub.dev on
2026-09-27) would have shown up on the board as false reds — no
`Package.swift`, no `.so`, because they aren't plugins at all.

## Automated Test Results

```
$ dart analyze --fatal-infos
Analyzing readiness_check...
No issues found!

$ dart format --output=none --set-exit-if-changed .
Formatted 8 files (0 changed) in 0.01 seconds.

$ dart test
00:00 +0: loading test/swiftpm_check_test.dart
00:00 +1: test/swiftpm_check_test.dart: checkSwiftPmReadiness tag and archive agree: both say ready
00:00 +2..+7: test/package_archive_test.dart: listArchiveEntryPaths ... (6 cases)
00:00 +8: test/plugin_discovery_test.dart: discoverFlutterPlugins keeps only sdk:flutter + is:plugin packages with an ios or android tag, dropping pure-Dart Flutter packages like provider
00:00 +9: test/plugin_discovery_test.dart: discoverFlutterPlugins preserves the ranking order of the completion-data list
00:00 +10: test/plugin_discovery_test.dart: discoverFlutterPlugins counts topN after filtering and stops fetching once N are found
00:00 +11: test/plugin_discovery_test.dart: discoverFlutterPlugins carries the fetched tags on the returned candidate
00:00 +12: All tests passed!
```

Run offline against a fake `http.Client` (`package:http/testing.dart`'s
`MockClient`) — zero network calls, per SPEC §5. Ran the whole
`readiness_check` package suite (12 tests, including e1-s2's SwiftPM and
archive tests), not just the changed file, to confirm the rework didn't
regress `plugin_discovery.dart`'s consumers.

## Build Verification

No production build step applies to a library package. `dart analyze
--fatal-infos` (exit 0) and `dart format --output=none --set-exit-if-changed
.` (exit 0) both pass.

## Acceptance Criteria Check

- A package without `is:plugin` is never returned — covered by the
  `provider` case in the filter test (real pub.dev tags: `sdk:flutter`,
  `platform:android`, `platform:ios`, no `is:plugin`).
- With enough plugins in the ranked list, `topN: N` returns exactly N
  plugins, in ranking order — covered by the topN test (`topN: 1` against a
  ranked list of `[provider, url_launcher, shared_preferences]` returns
  exactly `[url_launcher]`).
- `dart analyze --fatal-infos` clean and `dart test` passes offline — done,
  see above.

## Known Issues / Limitations

- Same as the original report: tag fetches are sequential (one HTTP call per
  candidate name), which is now slightly cheaper on average since fetching
  stops as soon as `topN` matches are found instead of always walking the
  full raw top-N slice.
- No integration test against the live pub.dev API — covered later by e6-s1
  (recorded fixtures) and e6-s2 (golden CLI tests), per this microtask's
  discovery/filtering-only scope.

## Suggested Commit Message

```
Fix plugin_discovery topN semantics and require is:plugin

topN now counts real Flutter plugins after the sdk:flutter/is:plugin/
platform filter instead of raw ranked names before it, and the filter
itself now requires is:plugin so pure-Dart Flutter packages (provider,
flutter_map) that carry every platform tag stop showing as false reds.
```
