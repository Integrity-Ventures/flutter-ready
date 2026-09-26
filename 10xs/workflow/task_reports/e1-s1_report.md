# Completion Report: e1-s1 — Plugin discovery and filtering

Instruction: `10xs/workflow/instructions/20260926_01_plugin-discovery.md`

## Work Completed

New Dart package `packages/readiness_check/` — the shared readiness-check
library named in SPEC.md §3.1.1.

| File | Lines | Purpose |
|---|---|---|
| `pubspec.yaml` | 16 | Package manifest: `http` dependency, `lints`/`test` dev deps |
| `analysis_options.yaml` | 1 | Lints config |
| `lib/readiness_check.dart` | 2 | Public export file |
| `lib/src/pub_dev_client.dart` | 50 | HTTP wrapper for `package-name-completion-data` and `packages/<name>/score`, injectable `http.Client` |
| `lib/src/plugin_discovery.dart` | 43 | `discoverFlutterPlugins(client, {topN = 100})`: takes the top-N ranked names, fetches score tags, keeps `sdk:flutter` + (`platform:ios` or `platform:android`) |
| `test/plugin_discovery_test.dart` | 82 | Unit tests (exempt from file-count limit) |

All implementation files are well under the 150-line stop-and-refactor limit.

## Design Notes

- `topN` is applied to the raw, ranking-ordered list *before* the tag filter,
  matching SPEC §3.1.1's "Take the top N ... keep only ..." — so the result
  can be smaller than `topN` once non-Flutter Dart packages are dropped. N
  itself is still an open decision (SPEC §7.1); default is 100 per the board
  checklist.
- `discoverFlutterPlugins` returns `PluginCandidate` (name + tags), not bare
  names, so the SwiftPM check (e1-s2) can read `is:swiftpm-plugin` off the
  same tag list already fetched here instead of re-hitting the score endpoint.
- Endpoint response shapes were confirmed live against pub.dev on 2026-09-26
  (`GET /api/package-name-completion-data` → `{"packages": [...]}`;
  `GET /api/packages/url_launcher/score` → tags including `sdk:flutter`,
  `platform:ios`, `platform:android`, `is:swiftpm-plugin`), and those shapes
  are what the fake `http.Client` in the tests reproduces.

## Automated Test Results

```
$ dart analyze
Analyzing readiness_check...
No issues found!

$ dart test
00:00 +0: loading test/plugin_discovery_test.dart
00:00 +0: test/plugin_discovery_test.dart: discoverFlutterPlugins keeps only sdk:flutter packages with an ios or android tag
00:00 +1: test/plugin_discovery_test.dart: discoverFlutterPlugins preserves the ranking order of the completion-data list
00:00 +2: test/plugin_discovery_test.dart: discoverFlutterPlugins applies topN to the raw list before filtering
00:00 +3: test/plugin_discovery_test.dart: discoverFlutterPlugins carries the fetched tags on the returned candidate
00:00 +4: All tests passed!
```

Tests run against a fake `http.Client` (`package:http/testing.dart`'s
`MockClient`) — zero network calls, per SPEC §5's "tests never call the
network".

## Build Verification

No production build step applies to a library package. `dart analyze` (exit
0) and `dart format --output=none --set-exit-if-changed .` (clean after
running `dart format .`) both pass.

## Known Issues / Limitations

- Tag fetches are sequential, one HTTP call per candidate name — fine for a
  nightly job at N≈100, but worth revisiting if N grows much larger.
- No integration test against the live pub.dev API. That risk is explicitly
  covered later by e6-s1 (recorded fixtures) and e6-s2 (golden CLI tests); this
  microtask's scope is discovery/filtering logic only, per the board
  checklist.
- No UI component in this microtask, so no screenshot evidence applies.

## Suggested Commit Message

```
Add shared readiness_check package with plugin discovery and filtering

Implements SPEC §3.1.1: fetch pub.dev's ranked package-name-completion-data
list, take the top N (default 100), and keep packages tagged sdk:flutter
plus platform:ios or platform:android.
```
