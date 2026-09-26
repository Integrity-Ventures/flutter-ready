# e6-s1: Fixtures — completion report

Instruction: `10xs/workflow/instructions/20260927_09_e6-s1-fixtures.md`

Commit: `a54fa59e57e9f59334956966df13910ddb1d6487`

## Work completed

New fixture pool at `packages/readiness_check/test/fixtures/`, plus one
test exercising it and one small analyzer config change:

| File | Lines | Notes |
|---|---|---|
| `test/fixtures/fixture_loader.dart` | 22 | `fixtureBytes`/`fixtureJson`/`fixtureTags` helpers |
| `test/fixtures/generate_fixtures.dart` | 160 | Regenerates `archives/` and `so_files/` from `sources/`; not a test |
| `test/fixtures_test.dart` | 154 | Runs the real checks against every fixture |
| `test/fixtures/README.md` | 71 | Provenance: what's real vs. synthetic, capture dates, why |
| `analysis_options.yaml` | +5 | Excludes `test/fixtures/sources/**` (see below) |

Fixture data (not implementation): `pub_dev/*.json` (9 files, recorded
pub.dev responses), `sources/**` (10 plain-text files the generator packs),
`archives/*.tar.gz` (5, generated), `so_files/*.so` (2, generated). Total
fixture tree is 112 KB.

### What each fixture represents

- **SwiftPM present**: the federated `url_launcher` set — `url_launcher`
  (app-facing, carries the tag) + `url_launcher_ios` (carries
  `Package.swift`), captured live from pub.dev 2026-09-26.
- **SwiftPM absent**: `flutter_barcode_scanner`, a real unfederated plugin
  last published 2021 (pre-dates SwiftPM) — no tag, no `Package.swift`,
  real Groovy `build.gradle`.
- **SwiftPM disagreeing**: `fixture_swiftpm_disagree`, synthetic (tagged
  ready, archive only has a podspec) — no real, stable instance of the
  flutter/flutter#187330 disagreement class was available to pin as a
  fixture, so this is fabricated and documented as such in the README.
- **Alignment**: `url_launcher_android`'s real archive has zero `.so` files
  (a real "no native libs in archive" case); `fixture_alignment_plugin` is
  synthetic, packing a real Gradle file with one 16 KB-aligned and one
  sub-16 KB synthetic `.so`. Standalone `.so` fixtures also exist for
  direct `checkSoAlignment` calls.
- **Android build settings**: exercised via `url_launcher_android`'s real
  Kotlin DSL (`compileSdk = flutter.compileSdkVersion`, an unresolved
  expression, real AGP `8.13.1`) and `flutter_barcode_scanner`'s real
  Groovy DSL (`compileSdkVersion 30`, AGP `4.1.3`).

### Notable implementation details

- `generate_fixtures.dart` pins every packed file's `lastModTime` to `0`.
  `package:archive`'s `ArchiveFile` defaults it to `DateTime.now()`, which
  made re-running the generator produce a byte-different `.tar.gz` every
  time for no reason — verified fixed by running the generator twice and
  diffing the SHA-256 of every output file (identical both times).
- `analysis_options.yaml` now excludes `test/fixtures/sources/**`: without
  that, `dart analyze` treats the fixture `pubspec.yaml` files as real
  package manifests and lints them (hit a real `deprecated_field` warning
  on the `flutter_barcode_scanner` fixture's `author:` field, which made
  `dart analyze --fatal-infos` exit 2).
- Existing test files under `packages/readiness_check/test/` are
  untouched — this card adds a fixture pool, it doesn't migrate the
  existing inline-fixture tests onto it.
- Real archive/JSON captures were made once, by hand, via `curl` against
  live pub.dev on 2026-09-26 — not from Dart test or generator code, so
  "tests never call the network" holds for both the test suite and the
  regeneration script.

## Automated test results

```
$ cd packages/readiness_check && dart analyze --fatal-infos
Analyzing readiness_check...
No issues found!
(exit 0)

$ dart test --reporter compact
...
+45: All tests passed!
```

All 45 tests pass, including the 8 new tests in `fixtures_test.dart`
(3 SwiftPM states, 3 alignment cases, 2 Android build-settings dialects)
plus 1 recorded-response assertion.

## Build verification

`dart pub get` + `dart analyze --fatal-infos` + `dart test` all exit 0 in
`packages/readiness_check`. Did not touch `packages/flutter_ready` or
`packages/snapshot_job` (pre-existing, unrelated analyzer noise there
turned out to be stale `.dart_tool` state from a fresh clone — resolved by
`dart pub get`, confirmed not caused by this change, left otherwise
untouched as out of scope).

## Known issues or limitations

- The disagreement-state fixture (`fixture_swiftpm_disagree`) is entirely
  synthetic, not a captured real instance — documented as such in
  `test/fixtures/README.md` and the instruction file, since no stable real
  package currently exhibits that disagreement.
- This card does not modify the root-level `fixtures/sample_app/` or
  `.github/workflows/verify-action.yml` — the 2026-09-27 architect note
  scoped that rework into e6-s2, which will reuse this card's fixture data.
- No visual/UI evidence needed — this card has no UI surface.

## Suggested commit message

```
Add readiness_check test fixtures (e6-s1)

One fixture per SwiftPM readiness state (present/absent/disagreeing),
a federated plugin set, and aligned/misaligned .so samples, so tests
never call the network.
```
