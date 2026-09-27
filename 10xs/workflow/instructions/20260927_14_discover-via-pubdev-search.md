# Microtask Instruction: discover plugins through pub.dev search, reds first (OPEN)

Status: **OPEN.** Written by the architect on 2026-09-27. The owner approved
changing how plugins are picked (SPEC §3.1.1). This supersedes
`20260927_12_e2-s1-rework3-scale-to-1000.md`. Executed by the card "Discover
plugins via pub.dev search".

## Why

- The owner wants the reds showcased at the top of the board.
- The current source, `/api/package-name-completion-data` ("overall
  ranking"), isn't "most used". Its top 100 left out `google_maps_flutter`,
  `flutter_native_splash`, `flutter_tts`, `open_filex`,
  `flutter_facebook_auth`, `flutter_downloader` and `video_compress`, all
  heavily downloaded and all lacking the `is:swiftpm-plugin` tag. That's why
  the board shows 0 reds.
- A `--top 1000` run over the old source crashed after 30 min
  (`FormatException: Filter error, bad data`, unhandled in assembly).

## Measured facts (architect, 2026-09-27)

- `GET https://pub.dev/api/search?q=<query>&sort=downloads&page=<n>` returns
  10 packages per page and **stops after page 10 (100 results max per
  query)**.
- `q=is:plugin platform:ios -is:swiftpm-plugin`, sorted by downloads, gives
  the 100 most-downloaded iOS plugins without the SwiftPM tag. Page 1:
  path_provider, path_provider_foundation, flutter_native_splash,
  google_maps_flutter_ios, google_maps_flutter, open_filex,
  google_mlkit_commons, flutter_tts, …
- The list includes federated platform packages (`*_ios`, `*_foundation`)
  and packages with no native iOS code (path_provider), so every candidate
  still needs the existing deep check.

## Changes

1. **Discovery** (readiness_check + snapshot_job): build the candidate set
   from two pub.dev searches, both `sort=downloads`, 10 pages each:
   - A, the likely reds: `is:plugin platform:ios -is:swiftpm-plugin`
   - B, context: `is:plugin` (the most-downloaded plugins overall)

   Merge them and dedupe. Fold federated platform packages into their
   app-facing plugin, so `google_maps_flutter_ios` counts under
   `google_maps_flutter`: drop a candidate when another candidate lists it
   as a `default_package`, and when it's a platform-only package whose
   app-facing plugin is also a candidate. Record each plugin's source
   (`"search": ["no-swiftpm", "top-downloads"]`) and its downloads.
   Keep `--top` meaning "pages per query × 10", default 100 per query.
2. **Deep check unchanged** (iOS resolution, nativeIos, not-ios-plugin,
   alignment, Gradle facts, errors). Additionally, **no per-plugin failure
   may abort the run**: catch stream and gzip errors around every fetch and
   decode, record them in `errors`, and carry on. Add an offline test with a
   corrupt `.tar.gz`.
3. **Concurrency 4** for search pages, score fetches and archives; a
   descriptive User-Agent; progress on stderr.
4. **Snapshot**: keep schemaVersion 1. Replace `topN` with
   `"discovery": {"method": "pubdev-search", "queries": [...], "resultsPerQuery": 100}`
   (the board reads it for its headline). Sort `plugins` by downloads,
   descending.
5. **SPEC.md §3.1.1**: rewrite "Pick the plugins" to describe the two
   searches and the 100-result cap, dated 2026-09-27 ("owner approved"). Keep
   the `is:plugin` rule.
6. **Regenerate the live data in the FOREGROUND** on the fleetbox:
   `data/snapshots/<UTC date>.json` + `data/latest.json`. In your report give
   the run time; the counts for Blocked, Unclear, Ready, Not affected and
   Errors; and the full red list with downloads and evidence, sorted by
   downloads. Delete `data/snapshots/2026-09-26.json` (graded with rules that
   were later fixed; git keeps it).

## Out of scope

- Board layout (reds-on-top headline, tiles, sort): that's the
  e3-s1 rework instruction `20260927_13_e3-s1-rework-reds-on-top.md`, which
  runs after this card. Keep the site building against the new snapshot:
  if a field it reads moved, adapt the reader minimally.

## Acceptance

- `dart analyze --fatal-infos` and `dart test` pass in all four packages.
- The live run exits 0, and the report has the numbers above.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground, lane branch
  `feature/discover-via-search`, and a report at
  `10xs/workflow/task_reports/discover-via-search_report.md`.
