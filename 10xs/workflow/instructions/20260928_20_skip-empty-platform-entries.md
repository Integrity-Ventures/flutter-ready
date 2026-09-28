# Microtask Instruction: skip empty platform entries in a pubspec (OPEN)

Status: **OPEN.** Found by the architect on 2026-09-28 after the gzip-padding
data run. Read `00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST and stop
if the claim fails.

`packages/readiness_check` only (plus regenerated data). No grading rule
changes.

## Finding

media_kit_video (2.0.1) is the one "Not checked" plugin on the board, with
`package info: type 'Null' is not a subtype of type 'Map<String, dynamic>' in type cast`.
Its pubspec on pub.dev lists `flutter.plugin.platforms.web: null` (measured
2026-09-28 via https://pub.dev/api/packages/media_kit_video).
`_packageInfoFromVersionJson` in
`packages/readiness_check/lib/src/pub_dev_client.dart` casts every
`platforms` entry to `Map<String, dynamic>`, so the null entry throws and
the whole plugin is lost.

## Fix

Skip a platform entry whose value is null (a platform declared with no
settings). Keep every other entry exactly as today. A non-null value that
isn't a map is still an error.

## Tests and check

- Offline test: a pubspec whose `platforms` has `"web": null` next to
  `ios` and `android` parses. `ios` and `android` are kept and `web` is
  skipped, so the plugin is still read as a Flutter plugin.
- `dart analyze --fatal-infos` and `dart test` in all four packages.
- Regenerate data in the FOREGROUND. media_kit_video gets a real verdict (or
  a different, real error). Quote every plugin whose result changed and
  explain each change; pub.dev search drift (plugins entering or leaving the
  list) is expected and should be listed separately.
- Lane branch `feature/skip-empty-platforms`, pushed to your clone's origin;
  report at `10xs/workflow/task_reports/skip-empty-platforms_report.md`.
