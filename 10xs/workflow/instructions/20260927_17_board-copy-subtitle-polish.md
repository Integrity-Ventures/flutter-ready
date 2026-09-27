# Microtask Instruction: board copy and subtitle polish (OPEN)

Status: **OPEN.** The owner approved this on 2026-09-27. It fixes two issues
the chethanprabhakar.com build-record session found on the live board.
Executed by the card "Board copy and subtitle polish". Read
`00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST and stop if the claim
fails.

site/ only. No data, grading, number or layout changes beyond the two items
below.

1. **Visitor-facing wording on plugin pages.** Under "Android build
   settings (facts only)", replace the internal text
   "What these mean for an app targeting API 36 is unresolved (SPEC open
   decision 3) — no colour yet."
   with plain wording:
   "We don't grade these yet; they're shown as facts."
   Search site/ for any other visitor-facing mention of "SPEC", "open
   decision" or card ids, and reword those the same way. Code comments may
   keep SPEC references.
2. **The subtitle widow at 1280px.** The header question "Is the plugin you
   depend on ready for CocoaPods going read-only and Play's API 36?" wraps
   "36?" onto its own line. Fix it with `text-wrap: balance` on the
   subtitle and/or a wider max-width, so that at 1280px it's one line or
   two balanced lines, and at 400px there's still no horizontal scroll.

## Check

- `dart analyze --fatal-infos` and `dart test` pass in site/ (and the other
  packages, untouched). `jaspr build` passes.
- Playwright screenshots of `/` and `/p/flutter_inappwebview/` at 1280x800
  and 400x800 under `10xs/workflow/evidence/polish-*.png`.
- Every number on `/` and the plugin pages is identical before and after.
- Lane branch `feature/board-polish`, pushed to your clone's origin; report
  at `10xs/workflow/task_reports/board-polish_report.md`.
