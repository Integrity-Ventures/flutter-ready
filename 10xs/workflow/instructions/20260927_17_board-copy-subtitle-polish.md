# Microtask Instruction: board copy, subtitle polish and HireFlutter header (OPEN)

Status: **OPEN.** The owner approved this on 2026-09-27. It fixes two issues
the chethanprabhakar.com build-record session found on the live board.
Executed by the card "Board copy and subtitle polish". Read
`00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST and stop if the claim
fails.

site/ only. No data, grading or number changes beyond the three items below.

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

3. **HireFlutter brand header** (owner-approved 2026-09-28, relayed by the
   chethanprabhakar.com session). Copy the header of the new site
   https://next-dev.d17nrypcqry4ka.amplifyapp.com/ on EVERY board page
   (`/` and `/p/<name>/`):
   - A slim header with the text wordmark **"HireFlutter.dev"** in the brand
     navy (`brandNavy`), Inter extra-bold, tight tracking, sized like
     next-dev's `text-xl font-extrabold tracking-tight`. The new site has no
     image logo; the wordmark IS the logo. It links to https://hireflutter.dev/.
   - Next to it, a **"Powered by 10xs"** pill styled like next-dev's
     (blue-50 background, blue text, xs semibold, full pill radius), hidden
     below the `sm` breakpoint (640px), as next-dev's `hidden sm:inline-flex`
     does, so it doesn't show at 400px. Its text must pass WCAG AA
     (4.5:1). next-dev's blue-500 on blue-50 is about 3.4:1, so darken the
     text to the nearest brand blue that passes (e.g. `brandBlueDark`) and
     give the ratio in the report.
   - "Flutter Ready" and the one-line question stay below that header as
     the product title.
   - The mascot `site/web/images/logo.svg` isn't rendered anywhere. Remove it
     (and any dead reference) unless you use it on purpose; say which in the
     report.
   All new colours go in `theme.dart`.

## Check

- `dart analyze --fatal-infos` and `dart test` pass in site/ (and the other
  packages, untouched). `jaspr build` passes.
- Playwright screenshots of `/` and `/p/flutter_inappwebview/` at 1280x800
  and 400x800 under `10xs/workflow/evidence/polish-*.png`, including `/p/path_provider/` at both widths.
- Every number on `/` and the plugin pages is identical before and after.
- Lane branch `feature/board-polish`, pushed to your clone's origin; report
  at `10xs/workflow/task_reports/board-polish_report.md`.
