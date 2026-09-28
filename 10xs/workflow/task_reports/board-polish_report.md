# Completion Report: Board copy and subtitle polish

Instruction: `10xs/workflow/instructions/20260927_17_board-copy-subtitle-polish.md@b586cf7d6d6e900e65826482ba175ac258e4c465`.
No new instruction file was written — the linked instruction already settles
this card's scope, per `00_ARCHITECT_GATE.md`'s "check this folder first" rule.

Branch: `feature/board-polish`, pushed to this clone's local `origin` per
`00_ARCHITECT_GATE.md`.

## Work completed

### 1. Visitor-facing wording

`site/lib/pages/plugin_page.dart`: replaced the internal sentence under
"Android build settings (facts only)" —
"What these mean for an app targeting API 36 is unresolved (SPEC open
decision 3) — no colour yet." — with
"We don't grade these yet; they're shown as facts."

Searched all of `site/` for other visitor-facing "SPEC", "open decision" or
card-id text (i.e. inside a `.text(...)` call, not a `///` doc comment).
Every other match is a code comment (kept, per the instruction). Confirmed
by grepping the built static HTML for both plugin pages and the index —
neither string appears anywhere in the rendered output.

### 2. Subtitle widow at 1280px

`site/lib/components/header.dart`: the `.tagline` rule now widens
`maxWidth` from `40.rem` to `46.rem` and adds `text-wrap: balance` (via
`raw: {'text-wrap': 'balance'}`, since the typed `Styles` API has no
`textWrap` property). At 1280px the subtitle now renders as a single line
(screenshotted); `text-wrap: balance` is kept as a defensive measure for
any narrower width where it does wrap, so a lone word never lands on its
own trailing line. At 400px it still wraps across 3 lines with no
horizontal scroll (screenshotted).

### 3. HireFlutter brand header

`site/lib/components/header.dart` gains a `.brand-bar` row above the
existing "Flutter Ready" title and tagline, rendered by the one `Header`
component every page (`/` and `/p/<name>/`) already shares via `app.dart`:

- `a.brand-wordmark` — the text "HireFlutter.dev", `brandNavy`, Inter
  extra-bold (`fontWeight: .w800`), `1.25.rem` (matching next-dev's
  `text-xl`), `-0.02em` letter-spacing, linking to
  `https://hireflutter.dev/`. No image logo, matching next-dev, which has
  none either.
- `span.powered-pill` — "Powered by 10xs", `display: none` by default and
  switched to `inline-flex` only at `min-width: 640px` (a
  `css.media(MediaQuery.screen(minWidth: 640.px), ...)` rule), so it's
  absent at 400px exactly like next-dev's `hidden sm:inline-flex`.
  Background is a new `pillBackground` token (`#eff6ff`, next-dev's
  blue-50). Text colour is `brandBlueDark` (`#1c3fae`), not next-dev's
  blue-500 — blue-500-on-blue-50 is only ~3.4:1, short of WCAG AA.
  **Computed contrast: brandBlueDark on pillBackground = 8.14:1** (WCAG
  relative-luminance formula), comfortably past the 4.5:1 threshold for
  small text.

`site/web/images/logo.svg` (the mascot) was never rendered by any
component (confirmed by grep before removal — only a comment in
`theme.dart` mentioned the file, and only to say it was unused/kept
as-is). Removed it and updated the comment; nothing else referenced it.

All new colours (`pillBackground`) live in `site/lib/constants/theme.dart`.

## Design notes

- **One `Header`, every page.** `app.dart` already renders a single
  `Header` component above the router for both `/` and every `/p/<name>`
  route, so the brand bar and pill needed no per-page wiring.
- **`text-wrap: balance` via `raw`.** Jaspr's typed `Styles.styles(...)`
  has no dedicated property for `text-wrap`; the `raw: Map<String,String>`
  escape hatch (already part of the API, used nowhere else in this repo
  yet) is the intended way to emit an arbitrary declaration.
- **Style-property ordering.** A fresh `dart pub get` in this clone (no
  `pubspec.lock` is committed — package convention) resolved a newer
  `jaspr_lints`/`lints` than the version other cards were built against,
  which added a `styles_ordering` info lint requiring named arguments to
  `.styles(...)` follow the constructor's declaration order. This flagged
  two pre-existing call sites outside this card's scope
  (`blocked_list.dart`, `hireflutter_cta.dart`) as well as my own new
  ones. Fixed all of them (pure argument reordering, no behavioural
  change) since `dart analyze --fatal-infos` passing is a hard requirement
  of this card's check, and left everything else in those two files
  untouched.

## Automated test results

```
$ cd site && dart analyze --fatal-infos
Analyzing site...
No issues found!

$ dart test
00:00 +28: All tests passed!

$ dart format --output=none --set-exit-if-changed .
Formatted 24 files (0 changed) in 0.06 seconds.
```

`dart analyze --fatal-infos` also re-run clean in `packages/readiness_check`,
`packages/flutter_ready` and `packages/snapshot_job` (all untouched by this
card, confirming the dependency-resolution drift above didn't affect them).

## Build verification

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in 53s; wrote 2046 outputs.

$ PATH="/usr/lib/dart/bin:$PATH" jaspr build
...
(147/147) Generating route "/p/apptentive_flutter" ...
Completed building project to /build/jaspr.
```

147 routes (146 plugins + index), 0 failures.

**Number parity.** Stashed this card's changes, rebuilt, and compared the
index headline and count tiles against the rebuild with changes applied:
both read "81 of the 146 most-downloaded iOS plugins checked here still
block iOS apps before CocoaPods goes read-only on 2 Dec 2026." with tiles
81 / 8 / 45 / 9 — identical before and after. Nothing in this card touches
`data/`, `grading.dart` or `board.dart`.

Served the build locally (`python3 -m http.server 8322`) and screenshotted
with Playwright (1.63.0) at 1280x800 and 400x800:

- `10xs/workflow/evidence/polish-index-1280x800.png` /
  `polish-index-400x800.png`
- `10xs/workflow/evidence/polish-flutter_inappwebview-1280x800.png` /
  `polish-flutter_inappwebview-400x800.png`
- `10xs/workflow/evidence/polish-path_provider-1280x800.png` /
  `polish-path_provider-400x800.png`

Visually confirmed on all three pages at both widths: the HireFlutter.dev
wordmark and (at 1280px only) the "Powered by 10xs" pill render above
"Flutter Ready"; the subtitle is one line at 1280px; nothing scrolls
horizontally at 400px; the plugin page's Android section shows the new
plain-language sentence.

## Known issues / limitations

- The `styles_ordering` fixes touch two files (`blocked_list.dart`,
  `hireflutter_cta.dart`) outside this card's stated scope. They are
  argument-order-only changes with no effect on rendered output (verified
  by the number-parity check and the screenshots, which include the
  blocked-plugins list and a red-row CTA), made only because the card's
  own check requires a clean `dart analyze --fatal-infos`.
- No `pubspec.lock` is committed for this package (repo convention), so a
  future `dart pub get` could again pull in a newer lint version; this
  isn't new risk introduced by this card.

## Suggested commit message

```
Polish board copy, fix subtitle widow, add HireFlutter brand header

Owner-approved 2026-09-27/28 (relayed by the chethanprabhakar.com
session). Three changes, site/ only:

1. Plugin pages: reworded the internal "SPEC open decision 3" sentence
   under Android build settings to plain visitor-facing copy ("We
   don't grade these yet; they're shown as facts.").
2. Header: widened the tagline's max-width and added text-wrap:
   balance so "Is the plugin you depend on ready for CocoaPods going
   read-only and Play's API 36?" no longer leaves "36?" stranded on
   its own line at 1280px, with no horizontal scroll at 400px.
3. Added a slim HireFlutter.dev brand bar (text wordmark, linking to
   hireflutter.dev) plus a "Powered by 10xs" pill above the existing
   Flutter Ready title, matching next-dev's header. The pill is
   hidden below 640px and uses brandBlueDark-on-blue-50 for an
   8.14:1 contrast ratio (WCAG AA requires 4.5:1). Removed the
   unused mascot logo.svg.

Also fixes styles-property-ordering lint hits in two unrelated
components (blocked_list.dart, hireflutter_cta.dart), surfaced by a
newer jaspr_lints resolved via a fresh pub get — argument reordering
only, no behavioural change.

Verified with dart analyze --fatal-infos, dart test, dart format, a
full jaspr build (147 routes), identical board numbers before/after,
and Playwright screenshots of / and two plugin pages at 1280x800 and
400x800.

Co-Authored-By: 10xs.ai
```
