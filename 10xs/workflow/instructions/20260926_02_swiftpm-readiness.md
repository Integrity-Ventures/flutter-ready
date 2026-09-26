# Microtask Instruction: e1-s2 — Swift Package Manager readiness check

## Objective

Give the shared `readiness_check` library a way to determine whether a plugin
is SwiftPM-ready: read pub.dev's `is:swiftpm-plugin` score tag, confirm it
against the package's own archive, and flag any plugin where the two signals
disagree.

## Context

- Builds on e1-s1 (`packages/readiness_check`, merged to `develop` at
  `7b4ef02`): `discoverFlutterPlugins` already returns a `PluginCandidate` per
  plugin carrying its full score tags, fetched once during discovery.
- SPEC §3.1.2: "pub.dev's `GET /api/packages/<name>/score` already carries an
  `is:swiftpm-plugin` tag (checked 2026-09-26 on `url_launcher`,
  `firebase_core` and `flutter_webrtc`). The tag isn't in pub.dev's API docs,
  so also confirm it from the package archive: a `ios/<plugin>/Package.swift`,
  `macos/<plugin>/Package.swift` or `darwin/<plugin>/Package.swift`. Record
  both, and flag any plugin where they disagree. Flutter's own tooling
  misreports this for some plugins (flutter/flutter#187330)."
- Confirmed live 2026-09-26: `GET /api/packages/url_launcher_ios/score` tags
  include `is:swiftpm-plugin`; its archive
  (`GET /api/archives/url_launcher_ios-6.4.2.tar.gz`) contains
  `ios/url_launcher_ios/Package.swift` — i.e. the `<plugin>` segment is the
  package's own name.
- `GET /api/packages/<name>` (distinct from the score endpoint) returns
  `{"latest": {"version", "archive_url", ...}}` — confirmed live 2026-09-26 —
  which is how the archive is located.
- No existing dependency can read tar.gz entry names; add the `archive`
  package (confirmed present on pub.dev, 2026-09-26) for that, since e1-s3
  (16 KB `.so` alignment) will need archive access too.

## Implementation Steps

1. `pubspec.yaml` — add `archive: ^4.3.0`.
2. `lib/src/pub_dev_client.dart` — add `fetchLatestArchiveUrl(name)` (GETs
   `/api/packages/<name>`, returns `latest.archive_url`) and
   `fetchArchiveBytes(uri)` (GETs the archive, returns raw bytes) to
   `PubDevClient`.
3. `lib/src/package_archive.dart` (new) — `listArchiveEntryPaths(bytes)`:
   decode a gzip-then-tar package archive (via `package:archive`) and return
   its entry paths, without extracting file contents.
4. `lib/src/swiftpm_check.dart` (new) — `checkSwiftPmReadiness(candidate,
   entryPaths)`: reads the `is:swiftpm-plugin` tag off `PluginCandidate.tags`,
   checks `entryPaths` for a `ios/<name>/Package.swift`,
   `macos/<name>/Package.swift` or `darwin/<name>/Package.swift` match, and
   returns a `SwiftPmReadiness` result carrying both booleans plus
   `agrees` (tag == archive).
5. `lib/readiness_check.dart` — export the new public symbols.
6. `test/swiftpm_check_test.dart` — pure logic tests for `checkSwiftPmReadiness`
   against literal entry-path lists (tag+archive agree present, agree absent,
   and both disagreement directions).
7. `test/package_archive_test.dart` — round-trips a small in-memory tar.gz
   built with `package:archive`'s encoders in test setup (no network, no
   fixture binary committed) through `listArchiveEntryPaths`.

## File Scope

Implementation (5 files, at the limit):
- `packages/readiness_check/pubspec.yaml`
- `packages/readiness_check/lib/src/pub_dev_client.dart`
- `packages/readiness_check/lib/src/package_archive.dart`
- `packages/readiness_check/lib/src/swiftpm_check.dart`
- `packages/readiness_check/lib/readiness_check.dart`

Test (exempt from the limit):
- `packages/readiness_check/test/swiftpm_check_test.dart`
- `packages/readiness_check/test/package_archive_test.dart`

## Acceptance Criteria

- `checkSwiftPmReadiness` reports the `is:swiftpm-plugin` tag and the archive
  match as two separate booleans, plus an `agrees` flag, per SPEC §3.1.2
  ("Record both, and flag any plugin where they disagree").
- The archive match looks for the package's own name under `ios/`, `macos/`,
  or `darwin/`, matching the real path shape confirmed above.
- No implementation file exceeds 150 lines.
- `dart analyze` is clean and `dart test` passes with zero network calls.

## Testing Strategy

Unit tests only: `swiftpm_check_test.dart` exercises the pure tag/archive
comparison logic against literal path lists (no archive bytes needed);
`package_archive_test.dart` builds a throwaway tar.gz in-memory with
`package:archive` and round-trips it through `listArchiveEntryPaths`, so
`dart test` still makes zero network calls. Fixture *package* archives
(recorded from real pub.dev responses) are e6-s1's scope, not this
microtask's.
