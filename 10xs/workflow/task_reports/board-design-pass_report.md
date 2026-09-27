# Board design pass in HireFlutter's brand — completion report

Instruction: `10xs/workflow/instructions/20260927_16_board-design-pass.md`

Branch: `feature/board-design-pass`

## Brand source

`https://next-dev.d17nrypcqry4ka.amplifyapp.com/` (checked 2026-09-27, HTTP
200). Extracted with a headless Chromium (Playwright) computed-style dump
of the live page — inline styles, not guesswork:

- Type: Inter (the only web font on that page).
- Ink: `#0f1932` (headings/body text), muted body copy around `#475569`-ish
  greys.
- Accent: `#2b5ff3` (buttons, the "before" highlight in the hero).
- Surfaces: `#f3f7fd` / `#fcfcfe` / `#eeeff4` (page tints), white cards.
- No separate logomark: `HireFlutter.dev` renders as a bold text wordmark,
  no icon/image. So there was no image to source — `web/images/logo.svg`
  (the existing mascot, already blue) is unchanged and untouched; the
  header wordmark is restyled to the brand's bold-navy treatment instead.

All of this now lives in `site/lib/constants/theme.dart` (`brandNavy`,
`brandBlue`, `brandBlueDark`, `surfacePage`, `surfaceCard`, `borderSubtle`,
`textMuted`, `fontFamilyName`) — no component has its own hex literal
(verified: `grep -rn '#[0-9a-fA-F]\{3,6\}' site/lib` only matches inside
`theme.dart`/`status_colors.dart`, plus one false positive that's a GitHub
issue number, `flutter/flutter#187330`, not a color).

## What changed, file by file

| File | Change |
|---|---|
| `constants/theme.dart` | New brand tokens (ink, accent, surfaces, muted text, `Inter`) replacing the old single `primaryColor` |
| `constants/status_colors.dart` | Same five statuses, same meanings, but each shade **darkened** from the original (e.g. amber `#fab219` → `#9a6300`) so it clears WCAG AA as text; added a light `*Bg` tint per status for pill backgrounds |
| `main.server.dart` | Swapped the Roboto Google Fonts import for Inter (still exactly one web font family); `html, body` now set the brand ink/page-tint colors |
| `components/header.dart` | Wordmark now bold brand navy on a white card with a hairline bottom border, tagline in the shared muted color |
| `components/count_tiles.dart` | Tiles are now tinted pills (bg = status tint, border/value = status color, label = muted) instead of white boxes with only a colored border |
| `components/status_chip.dart` | Rebuilt as a pill (tinted bg + colored text), replacing the dot-plus-plain-text chip — this is what makes the chip text itself pass AA, not just a decorative dot |
| `components/hireflutter_cta.dart` | Same copy, unchanged; the embedded link is now a solid brand-blue pill button (white text, AA 5.2:1), not a bare colored underline |
| `components/blocked_list.dart` | **New.** The blocked-plugin names, now a wrapped list of small red pill links, `<h2>Blocked plugins</h2>` + `<ul>`, each item still linking to `/p/<name>/` |
| `components/headline_panel.dart` | Reordered to headline → tiles → `BlockedList` (was headline → names → tiles) |
| `components/plugin_table.dart`, `trend_panel.dart`, `deadlines_panel.dart`, `pages/plugin_page.dart` | Stray hex → theme tokens; `plugin_table` also gained a rounded card wrapper with `overflow-x: auto`, fixing a real horizontal-scroll bug at 400px (see below) |

No file outside `site/` touched. No data/grading/CLI/Action file touched.

## Done-when, checked one by one

1. **First screen at 1280×800**: name+question (header), headline sentence,
   four tiles all render with room to spare — the blocked-plugin list only
   starts to peek in at the very bottom edge. Screenshot:
   `design-pass-after-index-1280x800.png`.
2. **Blocked names moved below the tiles**: confirmed in the same
   screenshot and in the built HTML — see the text-diff below.
3. **Brand colours/type/logo from theme.dart, no stray hex**: see the grep
   above.
4. **Status colours keep meaning, pass AA**: computed with the standard
   WCAG relative-luminance formula (not eyeballed). Foreground vs. its own
   tinted background: green 4.84:1, amber 4.59:1, red 4.86:1, grey 4.69:1,
   neutral (not-affected) 4.56:1 — all ≥ 4.5:1, so this holds even for the
   small chip text, not just the large tile numbers (which only need 3:1).
   The unmodified `statusAmber` (`#fab219`) was 1.83:1 on white — nowhere
   close; it had to move, not just get a background tint.
5. **Plugin pages share header/type/colours, CTA is a button**: same
   `Header` component (mounted once in `app.dart`, above the router, so
   both `/` and `/p/<name>` get it), same theme tokens, `a` links styled
   brand-blue; the HireFlutter CTA link is a filled pill button (nested
   selector so it wins specificity over the page's general `a` rule —
   verified by rendering, not just by reading the CSS).
6. **400px, no horizontal scroll**: `hasHScroll` (via
   `document.documentElement.scrollWidth > clientWidth`) is `false` on all
   6 before/after/page/viewport combinations except the **before** index
   page at 400px, which was `true` — a real bug (the un-scrollable table
   overflowing the viewport) that this pass fixes by giving the table its
   own `overflow-x: auto` card wrapper.
7. **Static HTML/CSS, one web font**: the only `<script>` is the
   pre-existing attention-filter toggle, untouched; Inter replaces Roboto
   1-for-1.
8. **Analyze/test green**: see below, including the other three packages.

## Evidence

Playwright (headless Chromium) screenshots at 1280×800 and 400×800, before
and after, for `/`, `/p/flutter_inappwebview/`, `/p/path_provider/`, under
`10xs/workflow/evidence/design-pass-{before,after}-*.png` (12 files).

Counts/headline byte-identical check — stripped both built `index.html`
files of `<script>`/`<style>` and all markup, diffed the remaining text
lines. Every number (`81`, `8`, `45`, `9`, `3`) and the headline sentence
are unchanged; the only diff is the blocked-name list relocating from
above the tiles to below them (plus its new `<h2>Blocked plugins</h2>`
label), exactly as specced:

```
$ python3 -c "...text-only diff of before/after build/jaspr/index.html..."
-flutter_inappwebview
-,
-google_maps_flutter
...
 81
 Blocked
 8
...
+Blocked plugins
+flutter_inappwebview
+google_maps_flutter
...
```

Same check on both plugin pages (`/p/flutter_inappwebview/`,
`/p/path_provider/`): **0 diff lines** — text content is fully unchanged
there (only presentation moved).

## Automated test results

```
$ cd site && dart analyze --fatal-infos
Analyzing site...
No issues found!

$ dart test
...
+28: All tests passed!
```

Also re-ran `dart pub get --offline && dart analyze --fatal-infos && dart
test` in the three untouched packages to confirm no regressions:
`readiness_check` (57 tests), `flutter_ready` (17 tests), `snapshot_job`
(10 tests) — all green, zero analyzer issues. (They needed a `pub get`
first in this clone; that's a local environment step, not a code change —
nothing under `packages/` was modified.)

## Known issues or limitations

- The Amplify build itself was not deployed or checked here — per the
  card, "The architect deploys and checks it after the merge."
- `web/images/logo.svg` (the mascot) is unchanged: the brand source has no
  separate logomark to swap in (see above), so there was nothing to
  replace it with. Flagged here rather than invented.
- The Google Fonts `Inter` `css.import` URL is fetched at request time, same
  as the Roboto import it replaces — no change in that respect.
- Per the architect gate: this branch was pushed to this clone's local
  `origin` (`~/flutter-ready`), not to github.com. The architect moves it
  from there.

## Suggested commit message

```
Board design pass in HireFlutter's brand (design-pass)

Restyle the board from default Roboto/browser-blue links to the new
HireFlutter site's brand (Inter, navy ink, one accent blue), sourced by
extracting computed styles from next-dev.d17nrypcqry4ka.amplifyapp.com.
Move the blocked-plugin names from a wall-of-links paragraph above the
count tiles to a scannable pill list below them, so the first screen at
1280x800 reads: name+question, headline, tiles. Darken the status palette
so every status color clears WCAG AA as text, not just as a decorative
dot. Fix a real horizontal-scroll bug at 400px width (the plugin table
overflowed the viewport) by giving it its own scrollable card. No data,
grading, snapshot, CLI, or Action changes — every count and the headline
sentence are byte-identical before and after.

Co-Authored-By: 10xs.ai
```
