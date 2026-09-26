# Completion Report: e1-s4 — Android build settings extraction

Instruction: `10xs/workflow/instructions/20260926_05_e1-s4-android-build-settings.md`

## Work Completed

Extends `packages/readiness_check` (from e1-s3, `develop` at `ca444e4`) with
Android build-settings extraction from SPEC §3.1.2.

| File | Lines | Purpose |
|---|---|---|
| `lib/src/android_build_settings.dart` | 88 | `AndroidBuildSettings {compileSdk, agpVersion, ndkVersion}`, `isAndroidGradleFilePath(path)`, `extractAndroidBuildSettings(androidGradleFileContents)` |
| `lib/readiness_check.dart` | 18 (+7) | Exports the new public symbols |
| `test/android_build_settings_test.dart` | 137 | Groovy and Kotlin DSL gradle text built by hand, covering both syntaxes, an unresolved-expression value, a commented-out declaration, AGP absent, and neither gradle file present |

Both implementation files are well under the 150-line stop-and-refactor limit
(largest is 88 lines).

## Design Notes

- `extractAndroidBuildSettings` takes the `Map<String, List<int>>` produced
  by the existing `extractArchiveEntries(bytes, isAndroidGradleFilePath)`
  (from e1-s2/e1-s3) — this microtask doesn't touch `package_archive.dart`,
  it only adds the Android-specific predicate and parser.
- Unlike the SwiftPM check, a plugin's Android Gradle file sits at a fixed
  archive-root path (`android/build.gradle` / `android/build.gradle.kts`),
  not nested under a per-plugin directory, so `isAndroidGradleFilePath`
  matches those two exact paths only.
- Extraction is regex-based text parsing, not a Gradle/Groovy/Kotlin parser
  — full parsing would need to run Gradle, which is out of scope (SPEC §4
  covers only archive-shipped content). One pair of patterns handles both
  the Groovy call form (`compileSdkVersion 34`) and the Groovy/Kotlin
  assignment form (`compileSdk = 34`); AGP version is read from either the
  Groovy `buildscript` classpath dependency or the Kotlin DSL `plugins`
  block, since a plugin's own gradle file commonly declares neither (AGP is
  normally the embedding app's concern).
- Declared values are recorded verbatim (quotes stripped) rather than
  requiring a numeric/string literal — plugins commonly defer to the
  embedding app via `flutter.compileSdkVersion` / `flutter.ndkVersion`
  (Flutter's own plugin template does this), and SPEC open decision 3 has
  not settled what these values mean yet, so the caller needs the raw text,
  not a value this microtask silently drops or nulls.
- No pass/fail/colour grading is attached to any field, per SPEC open
  decision 3 ("Until then v1 can show them as facts, without red, amber or
  green").
- `//` line comments are stripped before matching, so a commented-out
  setting (`// compileSdk 34`) isn't picked up as a false positive. Block
  comments (`/* ... */`) are out of scope for this microtask.
- Returns `null` (not a struct of all-null fields) when neither gradle file
  is present in the input map, distinguishing "no gradle file found" from
  "gradle file found but declares nothing."

## Automated Test Results

```
$ dart analyze --fatal-infos
Analyzing readiness_check...
No issues found!

$ dart test
00:00 +31: All tests passed!
```

31 tests total (23 pre-existing, 8 new in `android_build_settings_test.dart`).
Zero network calls: all gradle text is written by hand as Dart string
literals in the test file; no fixture files or archives are committed.

## Build Verification

No production build step applies to a library package. `dart analyze
--fatal-infos` (exit 0) and `dart format .` (no diff after running) both
pass.

## Known Issues / Limitations

- No live pub.dev archive was fetched for this microtask —
  `extractAndroidBuildSettings` is exercised only against hand-written
  gradle text. Wiring it against a real plugin's archive bytes (via
  `PubDevClient.fetchArchiveBytes` + `extractArchiveEntries`) is e2-s1's
  scope (snapshot assembly).
- Block comments (`/* ... */`) are not stripped, so a setting commented out
  only that way could still be matched. Not covered by SPEC §3.1.2's wording
  and not observed in the fixtures used for this microtask; flagging in case
  a real plugin exercises it.
- No UI component in this microtask, so no screenshot evidence applies.

## Suggested Commit Message

```
Add Android build settings extraction to readiness_check package

Implements SPEC §3.1.2: reads compileSdk, AGP version and NDK version
from a plugin's own android/build.gradle or build.gradle.kts as plain
facts, with no red/amber/green grading (SPEC open decision 3).

Co-Authored-By: 10xs.ai
```
