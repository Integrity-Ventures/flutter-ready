# Microtask Instruction: "Not affected" chip matches the board tile (OPEN)

Status: **OPEN.** The owner approved this on 2026-09-28 (relayed by the
chethanprabhakar.com session: "Agree with your recommendation"). Read
`00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST and stop if the claim
fails.

site/ only. No grading or data changes. Every tile count on `/` stays
byte-identical.

## Finding

The count tiles split a green SwiftPM result in two:
`site/lib/data/board.dart` `boardCategoryOf` gives `notAffected` when
`plugin.swiftpm.nativeIos == false`, and `ready` otherwise. But the SwiftPM
chip (`StatusChip`, label from `labelForStatus` in
`site/lib/constants/status_colors.dart`) only sees the colour, so every
green result says "Ready". So the 9 "Not affected" plugins (e.g.
path_provider: "Not affected: no native iOS code.") show a green "Ready"
chip on `/p/<name>/` and in the board's table rows, while the tile counts
them as "Not affected".

## Fix

1. One shared rule. The SwiftPM chip on the plugin page
   (`site/lib/pages/plugin_page.dart`) and in the table
   (`site/lib/components/plugin_table.dart`) must take its label from the
   same decision as the tiles (`boardCategoryOf`, or one helper both call).
   Don't copy the `nativeIos == false` test into a second place.
2. A green SwiftPM result with `nativeIos == false` shows **"Not affected"**,
   in the same green colours as "Ready" (it's all-clear, not a warning).
   Everything else keeps its current label.
3. The 16 KB alignment chip is unchanged (it has no "not affected" case).
4. Out of scope: the amber chip says "Caution" while its tile says
   "Unclear". Don't change it. Note it in the report; the owner decides
   separately.

## Tests and check

- A site test: path_provider's shape (green SwiftPM, `nativeIos: false`)
  gets the "Not affected" label; a green plugin with `nativeIos: true` gets
  "Ready"; the label and the tile category come from the same function.
- `dart analyze --fatal-infos` and `dart test` in site/ (and the other
  three packages, untouched). `jaspr build` passes.
- The tile counts on `/` are identical before and after (quote both).
- Playwright screenshots of `/p/path_provider/` and `/` at 1280x800 and
  400x800 under `10xs/workflow/evidence/not-affected-*.png`.
- Lane branch `feature/not-affected-chip`, pushed to your clone's origin;
  report at `10xs/workflow/task_reports/not-affected-chip_report.md`.
