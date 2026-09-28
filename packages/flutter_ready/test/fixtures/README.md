# flutter_ready readiness-check test fixtures

Fixtures for one readiness state each (SwiftPM present, absent, disagreeing)
plus aligned/misaligned `.so` samples, so tests never call the network
(SPEC §5, card e6-s1). Load them with `fixtures/fixture_loader.dart`.

## pub_dev/ — recorded pub.dev API responses

`<package>_score.json` is `GET /api/packages/<package>/score`.
`<package>_info.json` is `GET /api/packages/<package>`, trimmed to `name` and
`latest` (the client never reads the `versions` history, and it's ~100+
entries long on a real package).

| Package | Captured | State | Notes |
|---|---|---|---|
| `url_launcher` | 2026-09-26, live | SwiftPM present | Federated app-facing package; carries the `is:swiftpm-plugin` tag (SPEC §3.1.2: the tag comes from the app-facing package). |
| `url_launcher_ios` | 2026-09-26, live | SwiftPM present | The federated `ios.default_package` for `url_launcher`; its archive carries `Package.swift`. |
| `url_launcher_android` | 2026-09-26, live | n/a | The federated `android.default_package`; used for the Android build-settings and "no native libs in archive" alignment fixtures. |
| `flutter_barcode_scanner` | 2026-09-26, live | SwiftPM absent | Real, unfederated, pre-SwiftPM plugin (last published 2021): no `is:swiftpm-plugin` tag, no `Package.swift` in its archive. Also a real Groovy `build.gradle` with a resolved `compileSdkVersion`. |
| `fixture_swiftpm_disagree` | synthetic | SwiftPM disagreeing | Made up. Tagged `is:swiftpm-plugin` but its archive ships only a legacy podspec — the disagreement class SPEC §3.1.2 calls out via flutter/flutter#187330. A real, reproducible instance of that bug wasn't available to pin as a fixture, so this is fabricated to exercise the same code path deterministically. |

## sources/ — plain-text file contents, one directory per plugin

The actual `pubspec.yaml`, `Package.swift`, `build.gradle(.kts)` and
`.podspec` contents that get packed into the archives below. Kept as plain
files (not string constants in `generate_fixtures.dart`) so they're each
individually readable and diffable, and so real ones are visibly a straight
copy of what pub.dev served rather than something retyped.

Note: `analysis_options.yaml` excludes `test/fixtures/sources/**` — without
that, `dart analyze` treats every `pubspec.yaml` it finds, fixture or not,
as a real package manifest and lints it.

- `sources/url_launcher_ios/`, `sources/url_launcher_android/`,
  `sources/flutter_barcode_scanner/`: copied verbatim from the real pub.dev
  archives captured 2026-09-26 (source package/version noted in
  `generate_fixtures.dart`'s comments and the table above).
- `sources/fixture_swiftpm_disagree/`, `sources/fixture_alignment_plugin/`:
  wholly made up, to exercise the disagreement and mixed-alignment cases on
  demand.

## archives/ and so_files/ — regenerated, not hand-edited

Everything under `archives/*.tar.gz` and `so_files/*.so` is written by
`generate_fixtures.dart` from `sources/`; don't hand-edit the binaries. To
rebuild them:

```
cd packages/flutter_ready
dart run test/fixtures/generate_fixtures.dart
```

- `archives/url_launcher_ios.tar.gz`, `archives/url_launcher_android.tar.gz`,
  `archives/flutter_barcode_scanner.tar.gz` pack the real `sources/` files
  above, trimmed to just the `pubspec.yaml` and whichever `ios/`/`android/`
  file the readiness checks read — the real archives also carry IDE
  metadata, example apps and gradle wrapper jars the checks never look at.
- `archives/fixture_swiftpm_disagree.tar.gz` and
  `archives/fixture_alignment_plugin.tar.gz` pack the synthetic `sources/`
  files.
- `so_files/aligned_arm64-v8a.so` (LOAD alignment `0x4000`) and
  `so_files/misaligned_arm64-v8a.so` (`0x1000`) are minimal synthetic ELF
  files — header plus one `PT_LOAD` program header, no code — built the same
  way as `test/elf_alignment_check_test.dart`'s inline builder. Real
  prebuilt `.so` files shipped inside a pub.dev archive are rare (most
  plugins compile native code at app-build time) and, when they exist, run
  several megabytes — too large to commit as a fixture.

## Federated plugin set

`url_launcher` / `url_launcher_ios` / `url_launcher_android` together are
the federated fixture: `fixtures_test.dart` builds the SwiftPM
`PluginCandidate` from the app-facing package's tags but the platform
package's archive, per the federation rule (architect notes on e2-s1).
