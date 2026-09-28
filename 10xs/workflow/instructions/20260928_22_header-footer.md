# Microtask Instruction: calmer header and a company footer (OPEN)

Status: **OPEN.** The owner asked for both on 2026-09-28: "The header seems
too cluttered - we should unclutter it" and "I want my company name in the
footer ... Integrity Ventures Private Limited and its url is
https://ivp.life". Read `00_ARCHITECT_GATE.md` first: CLAIM THE CARD FIRST
and stop if the claim fails.

site/ only. No grading, data or number changes. Every count on `/` stays
identical.

## Why it feels cluttered (measured on the live board, 2026-09-28)

The top of `/` stacks five centred things before any data:
1. the "HireFlutter.dev" wordmark and "Powered by 10xs" pill,
2. the "Flutter Ready" title,
3. the question "Is the plugin you depend on ready for CocoaPods going
   read-only and Play's API 36?",
4. a white band ends, then a bold two-line headline ("83 of the 145 ...
   still block iOS apps before CocoaPods goes read-only on 2 Dec 2026."),
5. the count tiles.
Items 3 and 4 say nearly the same thing, and the centred brand line reads as
a second title. At 400px the data starts well below the fold.

## Header fix

1. **A slim top bar like a normal site nav**, full width, on every page:
   the "HireFlutter.dev" wordmark on the LEFT (same style and link as now),
   the "Powered by 10xs" pill on the RIGHT (same colours, same 640px hide
   rule), a thin bottom border. It sits in one row, about 56px tall.
2. **One hero, not two.** Below the bar: "Flutter Ready" as the page title,
   then ONE line of explanation. On `/` drop the separate question paragraph
   and keep the data headline as that line (it carries the numbers). On
   plugin pages keep a short one-line subtitle ("Is <name> ready for
   CocoaPods going read-only and Play's API 36?" or the current question).
   The hero is smaller: the title about 1.8rem at 1280 and 1.5rem at 400.
3. Remove the white band behind the old header, so the page is one
   background colour from the bar down.
4. At 400px: nothing wraps into more than 3 lines above the tiles, and
   there's no horizontal scroll.

## Footer (new, on every page)

A quiet footer at the bottom of every page, small muted text, centred:
- **"© 2026 Integrity Ventures Private Limited"**, where the company name
  links to **https://ivp.life** (opens in the same tab).
- A second line: "Open source (MIT) · Source on GitHub · Data from pub.dev,
  updated nightly", where "Source on GitHub" links to
  https://github.com/Integrity-Ventures/flutter-ready.
- Muted text colours must pass WCAG AA (4.5:1) on the footer background;
  give the ratio in the report. New colours go in `theme.dart`.

## Tests and check

- A site test: every page renders the footer with "Integrity Ventures
  Private Limited" linking to https://ivp.life, and the header bar with the
  wordmark and pill.
- `dart analyze --fatal-infos` and `dart test` in site/ (other packages
  untouched). `jaspr build` passes.
- All counts on `/` identical before and after (quote both).
- Playwright screenshots of `/` and `/p/flutter_inappwebview/` at 1280x800
  and 400x800, plus one full-page shot of `/` at 1280 showing the footer,
  under `10xs/workflow/evidence/header-footer-*.png`.
- Lane branch `feature/header-footer`, pushed to your clone's origin; report
  at `10xs/workflow/task_reports/header-footer_report.md`.
