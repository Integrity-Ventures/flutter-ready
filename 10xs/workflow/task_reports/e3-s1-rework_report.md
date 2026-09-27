# Task report: e3-s1 REWORK — reds on top, honest counts

Card: `added-board-reds-on-top-honest-counts-92d13d1a` ("Board: reds on top,
honest counts")
Instruction executed: `10xs/workflow/instructions/20260927_13_e3-s1-rework-reds-on-top.md`
Lane branch: `feature/board-reds-on-top` (the card's assigned branch name;
the instruction file itself names `feature/e3-s1-rework-reds-on-top` —
following the card, which is the live task assignment)
Commits: `c493619` (board logic + components), `4ca0f6c` (regenerated
jaspr codegen + evidence screenshots)

## Why this was reworked

The live board (before this card) showed "100% of the top 100 plugins
with a known status ship SwiftPM" — true but useless, because the shared
grading's `Status.green` merges "ships SwiftPM" with "not affected" and
hides that 0 were blocked. The owner: "It shows 100%. What is the use of
this?" Since then, the "Discover plugins via pub.dev search" card
replaced the old top-100-by-ranking source (which had missed
`google_maps_flutter`, `flutter_tts`, etc.) with two pub.dev searches, and
the live data now genuinely has 81 blocked plugins out of 146. This card
makes the board show that honestly, with reds first.

## What changed (site/ only — no changes to the shared `readiness_check` package)

- **`site/lib/data/board.dart`** (new): built entirely on top of
  `readiness_check`'s shared `swiftPmStatus`/`Status` (via
  `site/lib/data/grading.dart`'s re-export) rather than reimplementing
  red/amber/green rules.
  - `BoardCategory` (`blocked`/`unclear`/`ready`/`notAffected`/`notChecked`)
    splits `Status.green` back into "ships SwiftPM" vs "not affected"
    (`plugin.swiftpm.nativeIos == false`) — the exact split the 100%
    headline was missing.
  - `BoardCounts.from(plugins)`: one count per category, never merged.
  - `BoardRow` + `buildBoardRows(plugins)`: red, then amber, then grey
    (not checked), then green, downloads-descending within each group.
    Each row also carries `downloadRank` — its rank by 30-day downloads
    among *all* plugins, independent of the category-grouped table order,
    so a red row far down the table still shows how heavily it's used.
  - `headlineText({blocked, totalPlugins})`: worded from the discovery
    snapshot, not a "top N" rank (the candidate set is two merged pub.dev
    searches, not a single ranked list) — e.g. "81 of the 146
    most-downloaded iOS plugins checked here still block iOS apps before
    CocoaPods goes read-only on 2 Dec 2026." / "No plugin among the 146
    most-downloaded iOS plugins checked here blocks iOS apps today."
  - `formatDownloads`: `1,197,182`-style thousands grouping.

- **`site/lib/components/count_tiles.dart`** (new): one tile per
  `BoardCategory` — Blocked, Unclear, Ready, Not affected, and Not checked
  only when its count is `> 0` — each with its own colour (added
  `statusNeutral` to `status_colors.dart` for "not affected" so it's never
  drawn in the same green as "ready").

- **`site/lib/components/headline_panel.dart`** (new): the headline text,
  the blocked plugin names as links to their `/p/<name>` pages, then the
  tiles.

- **`site/lib/components/plugin_table.dart`** (rewritten): takes
  `List<BoardRow>` instead of raw plugins (rows arrive pre-sorted reds-on-top
  from `buildBoardRows`). Added `#` (download rank) and `Downloads (30d)`
  columns. Added the "Show only plugins that need attention" toggle:
  - A plain HTML checkbox + a small inline `<script>` (via jaspr's
    `script(content: ...)`, not a hydrated `@client` component — there
    wasn't one in this codebase yet and a vanilla script is enough for
    "small client-side toggle").
  - Every `<tr>` (plugin row and its HireFlutter CTA row) carries
    `data-attention="true"/"false"`.
  - **Without the script (or JS disabled), every row renders and stays
    visible** — the static HTML never hides anything itself. With JS, the
    script defaults the checkbox to checked and hides `data-attention="false"`
    rows, satisfying both "on by default when that set isn't empty" and
    "without JS, all rows show." Verified both states with Playwright
    (below).

- **`site/lib/components/trend_panel.dart`** (rewritten): the SwiftPM
  green-share percentage table is gone. Replaced with a per-snapshot-date
  counts table (Blocked/Unclear/Ready/Not affected via `BoardCounts.from`),
  plus the line "Counts use the grading rules of 2026-09-27; earlier
  snapshots were removed." The old percentage table is exactly what made
  2026-09-26's 88% and 2026-09-27's 100% look like plugins improved
  overnight, when the jump was really the grading fixes landing that day.

- **`site/lib/pages/index_page.dart`**: wires `buildBoardRows`,
  `BoardCounts.from`, the blocked-plugin sublist, and `HeadlinePanel` above
  the existing deadlines/trend/table sections.

- **`site/lib/constants/status_colors.dart`**: added `statusNeutral` and
  `colorForCategory`/`labelForCategory` for `BoardCategory` (the tile
  colours), alongside the existing `Status`-based helpers (unchanged,
  still used by the per-row `StatusChip`).

- `data/snapshots/2026-09-26.json` was already deleted by the
  discover-via-search card; nothing left to remove here.

- `site/lib/main.server.options.dart` (generated by `jaspr_builder`)
  regenerated to pick up the two new `@css` components.

## Scale (N = 1000)

Not tested by swapping `data/` permanently (nothing under `data/` was
committed as part of this scale check — see below). Two things prove it:

1. **`site/test/board_test.dart`**: a test builds 1000 synthetic
   `PluginEntry` values across all five categories and asserts
   `buildBoardRows` returns 1000 rows, sorted red/amber/grey/green with no
   boundary violations, in well under a second.
2. **A real `jaspr build`**, done in the foreground on the fleetbox
   against a temporary synthetic 1000-plugin snapshot (500 blocked/100
   unclear/200 ready/100 not-affected/100 not-checked, generated by a
   throwaway script, never committed): completed in 24s, 1001 routes (1000
   plugin pages + index), 0 failures. Served locally and screenshotted —
   headline, tiles (500/100/200/100/100), sort order, and the attention
   toggle (1200 of 1500 rows visible by default, i.e. exactly
   blocked+unclear+notChecked plugin rows plus their CTA rows) all held up.
   `data/latest.json` and `data/snapshots/` were restored from a backup
   immediately after and diffed byte-identical to the pre-swap originals;
   `git status` confirms no residual changes under `data/`.

## Tests and evidence

- `site/test/board_test.dart` (new): `boardCategoryOf` never merges
  categories; `BoardCounts.from` counts each category separately;
  `buildBoardRows` sorts red < amber < grey < green and downloads
  descending within a group, and download rank is independent of that
  table order; `headlineText` for both n > 0 and n = 0; `formatDownloads`
  grouping; the 1000-plugin scale case above.
- `site/test/grading_test.dart` (pre-existing, untouched): still passes —
  `Status`/`swiftPmStatus`/`alignmentStatus`/`isBlocked` are unchanged.
- Screenshots (full-page, 1400px viewport), taken by serving the real
  `jaspr build` output locally and capturing with Playwright:
  - `10xs/workflow/evidence/e3-s1-rework-real-data.png` — today's real
    data (146 plugins, 81 blocked). Headline, blocked-name links, five
    tiles (81/8/45/9, no "not checked" tile since... see note below),
    deadlines, trend, and the red-first table are all visible.
  - `10xs/workflow/evidence/e3-s1-rework-fixture-1000.png` — the synthetic
    1000-plugin fixture, showing the same layout holds at scale with a
    5th "Not checked" tile visible (100 > 0 in this fixture).

  Note: the real data's "Not checked" tile *is* present (3 > 0 — the
  `flutter_widgetkit`/`ios_insecure_screen_detector`/`media_kit_video`
  archive-decode errors from the discover-via-search run) — it renders
  below the first four tiles in the real-data screenshot, cropped out of
  the summary above but visible in the saved PNG.
- Playwright-driven checks (not committed, ad hoc verification): with JS,
  exactly 54 of 227 rows are hidden on the real board (45 ready + 9 not
  affected — never blocked/unclear/not-checked); with
  `javaScriptEnabled: false`, all 227 rows show. Confirms the toggle's
  "on by default" / "without JS, all rows show" requirement precisely.

## Gates

```
$ cd packages/readiness_check && dart analyze --fatal-infos && dart test
No issues found! / 57 tests passed

$ cd packages/snapshot_job && dart analyze --fatal-infos && dart test
No issues found! / 10 tests passed

$ cd packages/flutter_ready && dart analyze --fatal-infos && dart test
No issues found! / 17 tests passed

$ cd site && dart analyze --fatal-infos && dart test
No issues found! / 28 tests passed

$ cd site && jaspr build
Completed building project to /build/jaspr. (147 routes, real data)
```

All run individually right before the final commit, on the real
(restored) `data/`.

## Design notes / deviations

- Kept the per-row `StatusChip`/`Status` (green/amber/red/notChecked)
  exactly as before — the "never merge categories" requirement is scoped
  to the tiles (SPEC: point 1), not the per-row chip label, and the
  per-row evidence text already distinguishes "Not affected: no native
  iOS code." from "Package.swift found...". Not touched to avoid scope
  creep beyond the instruction.
- Table order (point 2) groups "ready" and "not affected" into one
  trailing "green" slot, matching the instruction's literal "red, amber,
  grey, green" — the tiles (point 1) are what keep those five categories
  visually distinct; the table's job is reds-on-top, not a fifth visual
  group.
- Went with a plain `<script>` + checkbox instead of introducing this
  codebase's first `@client` hydrated component, since "a small
  client-side toggle is OK" and the plain-script version needs zero build
  wiring, degrades to "all rows show" for free (no JS = no hiding logic
  runs at all), and was straightforward to verify both ways with
  Playwright.
- `swiftPmGreenSharePercent` (shared grading, `readiness_check`) is no
  longer called from `site` now that the trend is counts-based, but it's
  still a public export of the shared package and still tested in
  `site/test/grading_test.dart` — left in place rather than deleted, since
  removing shared public API wasn't asked for here.
