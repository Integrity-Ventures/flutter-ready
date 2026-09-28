# Completion Report: Header and footer

Instruction: `10xs/workflow/instructions/20260928_22_header-footer.md@bdbe42e975d58098ca1ff5dcb037080b7f897b94`.
No new instruction file was written — the linked instruction already settles
this card's scope, per `00_ARCHITECT_GATE.md`'s "check this folder first"
rule. No architect-specific note named this card id.

Branch: `feature/header-footer`, pushed to this clone's local `origin` per
`00_ARCHITECT_GATE.md`.

## Work completed

`site/` only. No grading, data or number changes.

### 1. A slim, page-independent top bar

`site/lib/components/header.dart` is now just the nav bar: the
"HireFlutter.dev" wordmark on the left (unchanged style/link), the
"Powered by 10xs" pill on the right (unchanged colours and 640px hide
rule), one row (~55px: `0.85em` vertical padding around the 1.25rem
wordmark), a thin bottom border, `justify-content: space-between`. The
old centred "Flutter Ready" `h1` and the tagline paragraph are gone from
this component — they were the source of the second, near-duplicate
sentence the instruction called out.

### 2. One hero, not two

New `site/lib/components/hero.dart`: a small shared component — "Flutter
Ready" as an `h1` linking home, then one `<p class="hero-subtitle">` of
page-specific explanation. Title is `1.8rem` at ≥480px and `1.5rem` below
that (a `css.media(MediaQuery.screen(maxWidth: 480.px), ...)` rule), so it
covers the 400px case from the instruction.

- **On `/`** (`site/lib/pages/index_page.dart`): the hero's subtitle is
  now the data headline itself (`headlineText(blocked:, totalPlugins:)`,
  the same sentence with the live numbers, e.g. "83 of the 145
  most-downloaded iOS plugins checked here still block iOS apps before
  CocoaPods goes read-only on 2 Dec 2026."). The old generic question
  paragraph is gone. To avoid showing that same sentence twice, I removed
  its second copy from `site/lib/components/headline_panel.dart` (which
  used to render `p.headline` with the identical text below the white
  band) — `HeadlinePanel` now only holds the count tiles and the blocked
  list, and dropped its now-unused `totalPlugins` parameter.
- **On `/p/<name>`** (`site/lib/pages/plugin_page.dart`): the hero's
  subtitle is personalized: "Is `<name>` ready for CocoaPods going
  read-only and Play's API 36?" (previously this exact plugin's page
  showed the same generic sentence every other page did).

No component sets a `surfaceCard` background behind the hero, so the old
"white band" is gone — the page is `surfacePage` (the body's colour) from
the top bar straight down to the tiles/content, per the instruction's
"one background colour from the bar down."

### 3. A company footer on every page

New `site/lib/components/footer.dart`, added once in `site/lib/app.dart`
below the router (so both `/` and every `/p/<name>` get it). Two centred
lines, small (`0.85rem`) and muted:

- "© 2026 **Integrity Ventures Private Limited**" — the company name
  links to `https://ivp.life`.
- "Open source (MIT) · **Source on GitHub** · Data from pub.dev, updated
  nightly" — "Source on GitHub" links to
  `https://github.com/Integrity-Ventures/flutter-ready`.

Both lines (and the two links, styled the same muted colour with a
semibold weight rather than a second colour, to keep the footer quiet)
use the existing `textMuted` token (`#475569`) on the page's `surfacePage`
background (`#f3f7fd`) — **contrast 7.05:1** (WCAG relative-luminance
formula), comfortably past the 4.5:1 AA threshold for small text. No new
colour was needed, so none was added to `theme.dart`.

`site/lib/app.dart`'s `.main` wrapper already used
`display:flex; flex-direction:column; min-height:100vh`; I wrapped the
`Router` in a `.page-content` div with `flex: 1` so the footer sits at
the bottom of the viewport on short pages instead of immediately after
the content.

## Automated test

`site/test/header_footer_test.dart` (new): renders `Header`, `Hero` and
`Footer` directly to HTML via `jaspr`'s own test-oriented
`renderComponent()` (exported from `package:jaspr/server.dart`,
`src/server/run_app.dart` — the same function `serveApp`/`runApp` build
on, intended for exactly this: rendering a component to a string outside
a running server) and asserts on the output:

- the top bar contains the HireFlutter.dev wordmark linking to
  `https://hireflutter.dev/` and the "Powered by 10xs" text,
- the hero contains "Flutter Ready" and the given subtitle,
- the footer contains "Integrity Ventures Private Limited" linking to
  `https://ivp.life`, and the GitHub/MIT line.

## Automated test results

```
$ cd site && dart analyze --fatal-infos
Analyzing site...
No issues found!

$ dart test
00:00 +36: All tests passed!

$ dart format --output=none --set-exit-if-changed .
(one file reformatted after the edit; committed already formatted)
```

`dart analyze --fatal-infos` also re-run clean in `packages/flutter_ready`
and `packages/snapshot_job` (both untouched by this card).

## Build verification

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in ~50s; wrote 2058 outputs.

$ PATH="/usr/lib/dart/bin:$PATH" jaspr build
...
(146/146) Generating route "/p/flutter_aepuserprofile" ...
Completed building project to /build/jaspr.
```

146 plugin routes + index, 0 failures.

**Number parity.** Stashed this card's changes (`git stash -u`), rebuilt,
and compared the built `/` against the rebuild with the changes applied:

| | Blocked | Unclear | Ready | Not affected | Total |
|---|---|---|---|---|---|
| Before | 83 | 8 | 45 | 9 | 145 |
| After | 83 | 8 | 45 | 9 | 145 |

Identical. Nothing in this card touches `data/`, `grading.dart` or
`board.dart`.

Served the build locally (`python3 -m http.server 8322`) and
screenshotted with Playwright (1.63.0):

- `10xs/workflow/evidence/header-footer-index-1280x800.png` /
  `header-footer-index-400x800.png`
- `10xs/workflow/evidence/header-footer-flutter_inappwebview-1280x800.png`
  / `header-footer-flutter_inappwebview-400x800.png`
- `10xs/workflow/evidence/header-footer-index-fullpage-1280.png` — full
  page at 1280, showing the footer at the bottom.

Visually confirmed on all screenshots: one slim top-bar row with the
wordmark and (only at 1280px) the pill; a single hero (title + one line)
with no separate white band; the footer at the bottom with the company
credit and GitHub/MIT line; at 400px nothing scrolls horizontally and the
hero subtitle itself never wraps past 3 lines (it wraps to exactly 3 at
400px in the index screenshot).

## Design notes

- **Where the headline text now lives.** The instruction's "keep the data
  headline as that line" only makes sense once per page; since the
  identical sentence used to render twice (once, generically, in the old
  `Header`'s tagline, and again, with real numbers, in
  `HeadlinePanel`), unifying it into one `Hero` per page meant deleting
  the second copy from `HeadlinePanel`, not just adding a third one in
  `Hero`. This also let `HeadlinePanel` drop its now-unused
  `totalPlugins` parameter.
- **`renderComponent` for the site test.** Jaspr ships no separate
  `jaspr_test` package; `renderComponent()` in
  `package:jaspr/src/server/run_app.dart` (re-exported from
  `package:jaspr/server.dart`) is the framework's own public,
  test-oriented entry point for rendering a component to HTML without a
  running HTTP server — the same function backs `serveApp`. Using it
  keeps the test to plain public API, no `implementation_imports`
  lint-suppression needed.
- **Footer link colour.** Used the existing muted colour
  (`textMuted`, differentiated by `font-weight: 600` rather than a
  second colour) instead of the site's link blue (`brandBlue`), to keep
  the footer reading as quiet, secondary text rather than a third
  navigation area. `brandBlue` on `surfacePage` measures 4.84:1, which
  would also have passed AA, but was visually louder than the "quiet
  footer" the instruction asked for.
- **56px vs ~55px top bar.** The instruction's "about 56px tall" is a
  target, not an exact assertion; at the default 16px root font size the
  bar (0.85em padding × 2 + the 1.25rem wordmark's line box) measures
  very close to that and is confirmed visually in the screenshots.

## Known issues / limitations

- `site/lib/main.server.options.dart` (generated by `jaspr_builder`)
  picked up two new `import`/style-collection lines for `Footer` and
  `Hero`; this is expected, mechanical churn from adding two components,
  not a hand edit.
- No `pubspec.lock` is committed for this package (repo convention), so
  dependency versions can drift between runs; unrelated to this card
  (noted previously in the board-polish report).

## Suggested commit message

```
Calmer header, one hero per page, and a company footer

Owner request 2026-09-28: "the header seems too cluttered" and "I want
my company name in the footer ... Integrity Ventures Private Limited
... https://ivp.life". site/ only, no grading/data/number changes.

1. Header is now just a slim, page-independent top bar: the
   HireFlutter.dev wordmark left, the Powered by 10xs pill right, one
   ~56px row. The old centred "Flutter Ready" title and tagline moved
   out of it.
2. New Hero component (title + one line) renders once per page, right
   below the bar, replacing two near-duplicate sentences with one: on
   `/` it's the live data headline (dropped from HeadlinePanel, which
   used to render the same sentence a second time); on `/p/<name>` it's
   a personalized question. No more white band behind the header — the
   page is one background colour from the bar down.
3. New Footer component on every page: "© 2026 Integrity Ventures
   Private Limited" (linking to ivp.life) plus an open-source/GitHub/
   data-source line. textMuted on the page background measures 7.05:1,
   past WCAG AA's 4.5:1.

Added a site test (header_footer_test.dart) that renders Header, Hero
and Footer via jaspr's own renderComponent() and asserts on the
output. Verified with dart analyze --fatal-infos, dart test (36
passing), a full jaspr build (146 routes), identical board counts
before/after (83/8/45/9), and Playwright screenshots at 1280x800 and
400x800 plus a full-page shot showing the footer.

Co-Authored-By: 10xs.ai
```
