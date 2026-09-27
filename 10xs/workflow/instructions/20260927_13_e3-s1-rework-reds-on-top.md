# Microtask Instruction: e3-s1 REWORK — reds on top, honest counts (OPEN, not done)

Status: **OPEN.** Written by the architect on 2026-09-27 from the owner's
request: "I do want to showcase the Reds on top." The owner also asked,
looking at the live board: "It shows 100%. What is the use of this?" A
worker launched on card e3-s1 executes THIS file.

## Problems on the live board (https://main.d1rgrd4z45pwk3.amplifyapp.com/)

1. The headline is "100% of the top 100 plugins with a known status ship
   SwiftPM". It's true but useless: it merges "ships SwiftPM" (89) with
   "not affected" (11), and hides that 0 are blocked.
2. The trend table compares 2026-09-26 (88%) with 2026-09-27 (100%). That
   jump comes from the architect's grading fixes on 2026-09-27, not from any
   plugin changing, so it's misleading.
3. The table is in pub.dev rank order, so red rows (the whole point) would
   be scattered or pushed below 100 green ones.

## Changes (site/, using readiness_check's shared grading)

1. **Headline block** above the table:
   - If there are blocked plugins: "**{n} of the top {N} Flutter plugins
     still block iOS apps before CocoaPods goes read-only on 2 Dec 2026.**"
     Show the n blocked plugin names right under it as links to their pages.
   - If there are none: "No plugin in the top {N} blocks iOS apps today."
   - Under it, four count tiles, one per deadline check (SwiftPM
     for now): **Blocked** (red), **Unclear** (amber, tag and archive
     disagree), **Ready** (ships SwiftPM), **Not affected** (no native iOS
     code / not an iOS plugin). Tiles never merge categories. Add **Not
     checked** (errors) only when > 0.
2. **Table order:** red rows first, then amber, then grey (not checked),
   then green. Within a group, sort by 30-day downloads, descending. Show
   rank and downloads in the table.
3. **A filter toggle** at the top of the table: "Show only plugins that
   need attention" (red + amber + grey). It's on by default when that set
   isn't empty. Keep it static-friendly: a small client-side toggle is OK;
   without JS, all rows show.
4. **Trend:** replace the percentage table with a counts table per snapshot
   date (Blocked / Unclear / Ready / Not affected). Delete
   `data/snapshots/2026-09-26.json` from the repo; it was graded with rules
   that were fixed on 2026-09-27, and git history keeps it. Add one line
   under the trend: "Counts use the grading rules of 2026-09-27; earlier
   snapshots were removed."
5. **Scale:** the page must still build and stay usable with N = 1000
   (the architect may raise N after measuring). Test the build with a
   synthetic 1000-plugin snapshot in a test or fixture, not committed as
   `data/`.

## Tests and evidence

- Grading and sort unit tests: red sorts before amber, before grey, before
  green, with downloads descending inside each group; the headline text for
  n > 0 and n = 0.
- `jaspr build` passes. Take full-page screenshots of the index with the
  real data (0 red today) and with a fixture snapshot that has reds. Save
  them under `10xs/workflow/evidence/e3-s1-rework-*.png`.
- `dart analyze --fatal-infos` and `dart test` pass in all four packages.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground, lane branch
  `feature/e3-s1-rework-reds-on-top`, and a report at
  `10xs/workflow/task_reports/e3-s1-rework_report.md`.
