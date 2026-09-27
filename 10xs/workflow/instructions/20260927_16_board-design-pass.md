# Microtask Instruction: board design pass in HireFlutter's brand (OPEN)

Status: **OPEN.** The card text below was approved by the owner on
2026-09-27 and relayed by the chethanprabhakar.com architect session.
Executed by the card "Board design pass in HireFlutter's brand". Read
`00_ARCHITECT_GATE.md` first.

The board at ready.hireflutter.dev works but has no design: default
Roboto, browser-blue underlined links, and the 81 blocked plugin names run
as one wall of links ABOVE the count tiles, so the first screen is a
paragraph of links, not the answer. SPEC.md §2 says the board is "in
HireFlutter's brand", and this card makes it so. Its first screen also
becomes the result image of Flutter Ready's build record on
chethanprabhakar.com/builds/, so the first screen at 1280x800 has to read
on its own.

Visual design only. No data, grading, snapshot, CLI or Action changes.
Every number and verdict on the page stays exactly as it is today.

## Files (work boundary)

site/lib/constants/theme.dart, site/lib/constants/status_colors.dart,
site/lib/components/*, site/lib/pages/index_page.dart,
site/lib/pages/plugin_page.dart, site/lib/app.dart, site/web/ (images,
favicon, fonts). Nothing outside site/ (plus your report and evidence
files).

## Brand source

The NEW HireFlutter site, not yet live:
https://next-dev.d17nrypcqry4ka.amplifyapp.com/ (answered 200 on
2026-09-27). Use its colours, type and logo. Do NOT use the current live
hireflutter.dev, which is being replaced. Take the values from there and
name the source in the report. If there's no usable brand source,
ask_owner before inventing one. Don't make up a palette.

## Done when

1. The first screen at 1280x800 shows, in this order: the product name and
   one-line question, the headline sentence, the four count tiles. The
   plugin-name list pushes nothing below the fold.
2. The blocked plugin names are no longer a run-on paragraph of links above
   the tiles. They move below the tiles into a scannable list or table
   (reds first, as now), each still linking to /p/<name>/.
3. Brand colours, type and logo come from the new HireFlutter site and live
   in theme.dart, with no stray hex values in components.
4. The status colours (Blocked, Unclear, Ready, Not affected, Not checked)
   keep their meaning and pass WCAG AA contrast for text on their
   backgrounds, in both the tiles and the chips.
5. Plugin pages (/p/<name>/) share the same header, type and colours, and
   the HireFlutter CTA is styled as a button, not a bare link.
6. Works at 400px wide with no horizontal scroll, and the tiles wrap
   cleanly.
7. It stays static HTML/CSS from Jaspr: no client-side JS added for
   styling, and first load isn't made heavier by more than one web font
   family. (The existing attention-filter toggle stays as it is.)
8. `dart analyze --fatal-infos` and `dart test` pass in site/ (and in the
   other three packages, untouched). The deployed Amplify build is green.
   The architect deploys and checks it after the merge.

## How to check

Playwright screenshots of `/`, `/p/flutter_inappwebview/` and
`/p/path_provider/` at 1280x800 and 400x800, before and after, saved under
`10xs/workflow/evidence/design-pass-*.png` and attached to the report. Check
that the counts and headline text are byte-identical before and after (diff
the text content of the built index.html, excluding markup).

Lane branch `feature/board-design-pass`, pushed to your clone's origin;
report at `10xs/workflow/task_reports/board-design-pass_report.md`.
