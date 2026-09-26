# Completion Report: e3-s1 — Board rendering

Instruction: `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md@c9835a3`
(section "e3-s1: Board rendering").

Branch: `feature/e3-s1-board-rendering`, commit `5fe13a7cd667dbdc3fe035d15b7375476d165836`,
pushed to this clone's local `origin` per `00_ARCHITECT_GATE.md`.

## Work Completed

Adds the `site/` package: a static [Jaspr](https://jaspr.site/) board that
reads `data/latest.json`, `data/snapshots/`, and `data/deadlines.json` at
build time and renders one index page plus one page per plugin at
`/p/<name>/` (SPEC §3.2). Also adds `data/deadlines.json`, which no prior
card had created — needed to display the three deadlines as data (SPEC
open decision 6).

| File | Purpose |
|---|---|
| `data/deadlines.json` | The three deadlines as data: CocoaPods read-only, Play API 36, 16 KB alignment (no date given in SPEC for the last one — left `null`, not guessed) |
| `site/lib/data/models.dart` | Parses the schemaVersion 1 snapshot/deadline JSON |
| `site/lib/data/grading.dart` | Pure grading functions: `swiftPmStatus`, `alignmentStatus`, their evidence strings, and `swiftPmGreenSharePercent` for the trend |
| `site/lib/data/data_source.dart` | Server-only `dart:io` reads of `../data/{latest,deadlines}.json` and `../data/snapshots/*.json` |
| `site/lib/app.dart` | Root `AsyncStatelessComponent`: loads the snapshot once, builds one literal `Route` per plugin (see Design Notes), requests static generation for each |
| `site/lib/pages/index_page.dart` | Deadlines panel + trend panel + the plugin table |
| `site/lib/pages/plugin_page.dart` | Per-plugin evidence detail, takes the already-loaded `PluginEntry` |
| `site/lib/components/{plugin_table,deadlines_panel,trend_panel,status_chip}.dart` | Board UI pieces |
| `site/lib/constants/status_colors.dart` | Fixed status palette (good/warning/critical/muted), colour + text label always paired |
| `site/test/grading_test.dart` | 10 unit tests on the grading functions |

## Design Notes

- **Static generation rejects path parameters.** `jaspr_router`'s
  `RouteRegistryImpl.registerRoutes` asserts `route.pathParams.isEmpty` in
  static mode — a single `Route(path: '/p/:name', ...)` throws at build
  time (verified: first build attempt failed with exactly this assertion).
  `App.build` (an `AsyncStatelessComponent`) instead loads the snapshot
  once and constructs one literal `Route(path: '/p/$name', ...)` per
  plugin, then calls `ServerApp.requestRouteGeneration('/p/$name')` for
  each so the static crawler (which starts at `/` and only discovers
  routes it's told about) finds them. This also let `PluginPage` become a
  plain `StatelessComponent` taking the already-loaded `PluginEntry`
  rather than re-reading `data/latest.json` per route.
- **Colour rules** (architect decision): SwiftPM green when tag and
  archive both say ready, amber when they disagree, red when both say not
  ready; 16 KB green when every `.so` is aligned or there are none, red on
  any misalignment (shown with path + `minAlign`); Android is facts only,
  no colour (SPEC open decision 3); any plugin with a non-empty `errors`
  list is grey "not checked", overriding the other two.
- **Trend as a stat tile, not a chart.** Per the dataviz skill's form
  heuristic, a single ratio with only one data point today (one snapshot
  committed so far) is a stat tile, not a chart — `TrendPanel` shows the
  current SwiftPM-ready share as a headline number, with a small history
  table underneath that will read sensibly as more nightly snapshots land.
- **Status chip never uses colour alone**: `StatusChip` pairs the coloured
  dot with a text label (Ready/Caution/Blocked/Not checked); body text
  stays in ink colours except the one deliberate exception (the "Could not
  be fully checked" errors block on the plugin page, which reuses the
  reserved critical-status colour for the same reason error text is
  usually red).
- `e3-s2` (red-row CTA) is explicitly out of scope here — no CTA text
  added. `e3-s3` (deployment) is HELD per the architect note; not touched.

## Automated Test Results

```
$ cd site && dart analyze --fatal-infos
Analyzing site...
No issues found!

$ dart test
00:00 +10: All tests passed!

$ dart format --output=none --set-exit-if-changed .
Formatted 18 files (0 changed) in 0.04 seconds.
```

## Build Verification

Ran the live static build on the fleetbox, in the foreground:

```
$ cd site && jaspr build
Building jaspr for static rendering mode.
...
Generating routes...
(1/1) Generating route "/" ...
(2/101) Generating route "/p/path_provider" ...
...
(101/101) Generating route "/p/qr_code_scanner_plus" ...
Completed building project to /build/jaspr.
```

101 routes (1 index + 100 plugin pages, matching `topN: 100` in
`data/latest.json`), 0 failures. Output is directory-style static HTML
(`build/jaspr/p/<name>/index.html`), 2.9 MB total.

Served the build output locally (`python3 -m http.server 8123`, chosen to
avoid the reserved 3000/3001/4000 ports) and captured screenshots with
Playwright (`npx playwright screenshot`) of the index page and the
`url_launcher` plugin page — confirmed the deadlines panel, the 88% trend
stat tile, the per-plugin table with coloured+labelled status chips and
evidence text, and the plugin detail page with SwiftPM/alignment/Android
evidence and a working "View on pub.dev" link. One issue found and fixed
during this pass: a duplicate global `h1 { font-size: 4rem }` rule left
over in the unedited scaffold's `constants/theme.dart` was overriding the
2rem `h1` set on `main.server.dart`'s `Document` — removed the dead
duplicate (jaspr_builder picks up every `@css`-annotated getter in `lib/`
regardless of imports, so both were being merged).

## Known Issues / Limitations

- Only one snapshot (`data/snapshots/2026-09-26.json`) exists, so the
  trend history table currently shows a single row. The code handles any
  number of snapshots.
- `data/deadlines.json`'s 16 KB alignment deadline has `date: null` — SPEC
  §1 gives no date for it, only "via slate §3"; not guessed.
- Branding (HireFlutter's brand, per SPEC §2) is out of scope here — the
  scaffold's default Jaspr favicon/logo assets are still in place. e3-s3
  (deployment) or a future card should replace them.
- `main.server.options.dart` / `main.client.options.dart` are committed,
  generated files (jaspr convention); they were regenerated once via
  `dart run build_runner build` after removing the duplicate theme.dart
  styles, to keep the tree consistent with the source.

## Suggested Commit Message

```
Add site/ package: Jaspr static board rendering (e3-s1)

Renders the readiness board as a static Jaspr site: one index page with
the deadlines, a SwiftPM-share stat tile, and a per-plugin table, plus
one static page per plugin at /p/<name>/ so each is individually
searchable (SPEC §3.2). Colour rules (SwiftPM green/amber/red, 16 KB
green/red, Android facts-only) follow the architect's e3-s1 decision.

jaspr_router asserts routes with path parameters are unsupported for
static-site generation, so App builds one literal Route per plugin from
the snapshot instead of a single /p/:name route. Also adds
data/deadlines.json (SPEC open decision 6), which no prior card had
created.

Verified with dart analyze --fatal-infos, dart test, and a full
jaspr build (101 routes generated) served locally and screenshotted
with Playwright.

Co-Authored-By: 10xs.ai
```
