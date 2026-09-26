# Microtask Instruction: e1-s4 — Android build settings extraction

## Objective

Give the shared `readiness_check` library a way to read the Android build
settings a plugin declares for itself — `compileSdk`, the Android Gradle
Plugin (AGP) version, and the NDK version — from the plugin's own
`android/build.gradle` or `android/build.gradle.kts`, as plain recorded
facts with no colour grading attached.

## Context

- Builds on e1-2/e1-3 (`packages/readiness_check`, `develop` at `ca444e4`):
  `package_archive.dart` already exposes `extractArchiveEntries(archiveBytes,
  predicate)`, returning entry content for archive entries matching a
  predicate. This microtask reuses that entry point; it does not touch
  `package_archive.dart`.
- SPEC §3.1.2: "**Android build settings** declared in the plugin's
  `android/build.gradle` or `build.gradle.kts`: `compileSdk`, the AGP version
  and the NDK version, when present. See open decision 3 on how these are
  graded."
- SPEC open decision 3: "The API 36 rule applies to the app's `targetSdk`,
  not to a plugin's. What a plugin's `compileSdk`, AGP or NDK setting means
  for an app targeting API 36 needs to be settled from sources before those
  columns get a colour. Until then v1 can show them as facts, without red,
  amber or green." This microtask therefore returns raw declared values only
  — no derived pass/fail/warn state.
- Unlike the SwiftPM check (SPEC §3.1.2, `swiftpm_check.dart`), a plugin's
  Android Gradle file is **not** nested under a per-plugin directory: a
  package archive puts it at the fixed paths `android/build.gradle` /
  `android/build.gradle.kts` at the archive root. There is normally only
  one of the two per plugin (Groovy or Kotlin DSL), never both.
- These are real build scripts, not data files — full Gradle/Groovy/Kotlin
  parsing is out of scope (no Gradle execution, no AST). Extraction is
  line-based regex over the file's text, matching how a plugin actually
  declares each setting:
  - Groovy, both call and assignment forms: `compileSdkVersion 34`,
    `compileSdk 34`, `compileSdk = 34`.
  - Kotlin DSL, assignment form: `compileSdk = 34`.
  - `ndkVersion` follows the same two shapes: `ndkVersion "25.1.8937393"`
    (Groovy call), `ndkVersion = "25.1.8937393"` (Kotlin/Groovy assignment).
  - A declared value is not always a literal — plugins commonly defer to the
    embedding app via `flutter.compileSdkVersion` / `flutter.ndkVersion`
    (Flutter's plugin template does this). Record whatever text follows the
    key verbatim (quotes stripped) rather than only accepting numeric
    literals — the caller decides later what an unresolved expression means.
  - AGP version is declared differently from the other two, and is often
    absent from a plugin's own `android/build.gradle` (it is normally the
    *app's* concern): either a Groovy `buildscript` classpath dependency —
    `classpath 'com.android.tools.build:gradle:7.3.0'` — or a Kotlin DSL
    `plugins` block — `id("com.android.library") version "8.1.0"`.
  - Commented-out lines (`// compileSdk 34`) must not produce a false
    match — strip `//` line comments before matching. Block comments
    (`/* ... */`) are out of scope for this microtask.

## Implementation Steps

1. `lib/src/android_build_settings.dart` (new):
   - `class AndroidBuildSettings`: `compileSdk` (nullable String),
     `agpVersion` (nullable String), `ndkVersion` (nullable String) — each
     the raw declared text (quotes stripped), or null when the setting is
     not present in the file.
   - `bool isAndroidGradleFilePath(String path)`: true for exactly
     `android/build.gradle` or `android/build.gradle.kts` — the predicate a
     caller passes to `extractArchiveEntries`.
   - `AndroidBuildSettings? extractAndroidBuildSettings(Map<String,
     List<int>> androidGradleFileContents)`: takes the map produced by
     `extractArchiveEntries(bytes, isAndroidGradleFilePath)`. Returns `null`
     when neither gradle file is present. Otherwise UTF-8 decodes whichever
     file is present, strips `//` line comments, and regex-extracts
     `compileSdk`/`compileSdkVersion`, `ndkVersion`, and the AGP version
     (checking the classpath form, then the Kotlin DSL `plugins` form).
2. `lib/readiness_check.dart` — export `AndroidBuildSettings`,
   `extractAndroidBuildSettings`, `isAndroidGradleFilePath`.
3. `test/android_build_settings_test.dart` (new) — covering, for both
   Groovy and Kotlin DSL sample gradle text built in the test file (no
   fixture files, no network, same in-memory approach as e1-s2/e1-s3):
   - Groovy `build.gradle`: `compileSdkVersion` call form, `ndkVersion`
     call form with a quoted literal, AGP via `buildscript` classpath.
   - Kotlin DSL `build.gradle.kts`: `compileSdk =`, `ndkVersion =`
     assignment forms, AGP via the `plugins { id(...) version ... }` form.
   - A declared value that is an unresolved expression
     (`compileSdk = flutter.compileSdkVersion`) is recorded verbatim, not
     dropped or nulled.
   - A commented-out setting (`// compileSdk 34`) is not picked up.
   - A gradle file with no AGP declaration at all (the common case for a
     plugin) — `agpVersion` is null while `compileSdk`/`ndkVersion` are
     still populated.
   - Neither `android/build.gradle` nor `android/build.gradle.kts` present
     in the map — `extractAndroidBuildSettings` returns `null`.

## File Scope

Implementation (2 files, well under the 5-file limit):
- `packages/readiness_check/lib/src/android_build_settings.dart`
- `packages/readiness_check/lib/readiness_check.dart`

Test (exempt from the limit):
- `packages/readiness_check/test/android_build_settings_test.dart`

## Acceptance Criteria

- `extractAndroidBuildSettings` reads `compileSdk`, AGP version and NDK
  version from both Groovy and Kotlin DSL gradle text, recording the raw
  declared value (including unresolved expressions like
  `flutter.compileSdkVersion`) rather than only literals.
- No colour/pass-fail grading is attached to any field — SPEC open decision
  3 is unresolved, so this microtask returns facts only.
- Commented-out declarations are not matched.
- Returns `null` when neither gradle file is present in the input map,
  rather than a struct of all-null fields.
- No implementation file exceeds 150 lines.
- `dart analyze --fatal-infos` is clean and `dart test` passes with zero
  network calls.

## Testing Strategy

Unit tests only, all offline: `android_build_settings_test.dart` builds
Groovy and Kotlin DSL gradle file text by hand as Dart string literals
(mirroring the synthetic-buffer approach `elf_alignment_check_test.dart`
used for ELF bytes), covering both syntaxes, the unresolved-expression case,
the commented-out case, the AGP-absent case, and the neither-file-present
case.
