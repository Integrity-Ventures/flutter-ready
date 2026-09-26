# Completion Report: e1-s2 — Swift Package Manager readiness check

Instruction: `10xs/workflow/instructions/20260926_02_swiftpm-readiness.md`

## Work Completed

Extends `packages/readiness_check` (from e1-s1, merged to `develop` at
`7b4ef02`) with the SwiftPM readiness check from SPEC §3.1.2.

| File | Lines | Purpose |
|---|---|---|
| `pubspec.yaml` | +1 | Adds `archive: ^4.3.0` dependency |
| `lib/src/pub_dev_client.dart` | 67 (+17) | Adds `fetchLatestArchiveUrl(name)` (`GET /api/packages/<name>` → `latest.archive_url`) and `fetchArchiveBytes(uri)` to `PubDevClient` |
| `lib/src/package_archive.dart` | 9 | `listArchiveEntryPaths(bytes)`: gzip-then-tar decode via `package:archive`, returns entry paths only |
| `lib/src/swiftpm_check.dart` | 41 | `checkSwiftPmReadiness(candidate, entryPaths)` → `SwiftPmReadiness {tagSaysReady, archiveSaysReady, agrees}` |
| `lib/readiness_check.dart` | 4 (+2) | Exports the new public symbols |
| `test/swiftpm_check_test.dart` | 96 | Tag/archive agreement and both disagreement directions, plus dir variants (`ios`/`macos`/`darwin`) and a same-name-different-plugin negative case |
| `test/package_archive_test.dart` | 39 | Round-trips an in-memory tar.gz built with `package:archive`'s own encoders through `listArchiveEntryPaths` |

All implementation files are well under the 150-line stop-and-refactor limit
(largest is 67 lines).

## Design Notes

- `checkSwiftPmReadiness` takes `PluginCandidate` (already carrying score tags
  from e1-s1's discovery) plus a plain `List<String>` of archive entry paths,
  rather than fetching either itself — keeping this file's only job the SPEC
  §3.1.2 comparison, with fetching left to `PubDevClient` and archive
  decoding to `package_archive.dart`.
- The archive match looks for `<dir>/<candidate.name>/Package.swift` under
  `ios/`, `macos/`, or `darwin/` — confirmed live 2026-09-26 against
  `url_launcher_ios` 6.4.2's real archive, which contains exactly
  `ios/url_launcher_ios/Package.swift`.
- `SwiftPmReadiness.agrees` is `tagSaysReady == archiveSaysReady`, covering
  both disagreement directions named in SPEC §3.1.2 and flutter/flutter#187330,
  not just "tag says yes, archive says no".
- `archive` (package:archive) is a new dependency, chosen because e1-s3 (16 KB
  `.so` alignment) will need the same archive-decoding path.
- `fetchLatestArchiveUrl` hits a different endpoint (`/api/packages/<name>`)
  than `fetchPackageTags` (`/api/packages/<name>/score`) — confirmed live
  2026-09-26 that only the former carries `latest.archive_url`.

## Automated Test Results

```
$ dart analyze
Analyzing readiness_check...
No issues found!

$ dart test
00:00 +12: All tests passed!
```

12 tests total (6 new `swiftpm_check_test.dart`, 2 new
`package_archive_test.dart`, 4 pre-existing `plugin_discovery_test.dart`).
Zero network calls: `package_archive_test.dart` builds its own throwaway
tar.gz in-memory with `package:archive`'s encoders rather than fetching a real
archive; `pub_dev_client.dart`'s new methods are exercised indirectly (their
shapes were confirmed live against pub.dev during instruction-writing, per
the instruction file) and are covered by fixtures in e6-s1, not here.

## Build Verification

No production build step applies to a library package. `dart analyze` (exit
0) and `dart format --output=none --set-exit-if-changed .` (clean after
running `dart format .`) both pass.

## Known Issues / Limitations

- `PubDevClient.fetchLatestArchiveUrl` / `fetchArchiveBytes` have no direct
  unit test in this microtask — only the pure `checkSwiftPmReadiness` and
  `listArchiveEntryPaths` logic is tested against literal/round-tripped data.
  Wiring live pub.dev archive fetches into a fixture-backed test is e6-s1's
  scope (recorded API/archive fixtures), not this microtask's.
- No UI component in this microtask, so no screenshot evidence applies.

## Suggested Commit Message

```
Add SwiftPM readiness check to readiness_check package

Implements SPEC §3.1.2: reads the is:swiftpm-plugin score tag, confirms it
against a ios/macos/darwin Package.swift in the package's own archive, and
flags any plugin where the two signals disagree.

Co-Authored-By: 10xs.ai
```
