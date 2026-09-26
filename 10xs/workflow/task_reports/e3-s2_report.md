# Completion Report: e3-s2 — Red-row call to action

Instruction: `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md@c9835a3`
(section "e3-s2: Red-row call to action"). No new instruction file was written —
the architect note already settles this card's scope and copy, per
`00_ARCHITECT_GATE.md`'s "check this folder first" rule.

Branch: `feature/e3-s2-red-row-cta`, commit `cd69bb5d793f43bd939f062a01dcbedf0bbb4b86`,
pushed to this clone's local `origin` per `00_ARCHITECT_GATE.md`.

## Work Completed

Adds the HireFlutter call to action to every red row and red plugin page
(SPEC §2, §3.2; architect note): "Blocked by this plugin? A HireFlutter
developer can migrate or fork it.", linking to `https://hireflutter.dev`.

| File | Purpose |
|---|---|
| `site/lib/data/grading.dart` | Adds `isBlocked(PluginEntry)`: true when either `swiftPmStatus` or `alignmentStatus` is `Status.red`. Lives next to the other grading functions so the table and the plugin page can't disagree on what counts as "red" |
| `site/lib/components/hireflutter_cta.dart` | New reusable `HireFlutterCta` component: the CTA paragraph with the link, styled in the reserved critical-status colour (`statusRed`) |
| `site/lib/components/plugin_table.dart` | `_row` renamed `_rows` and now returns a list: the plugin's row, plus (when `isBlocked`) a full-width `tr.cta-row` with a `colspan="5"` cell holding the CTA, directly under the row it applies to |
| `site/lib/pages/plugin_page.dart` | Renders `HireFlutterCta` under the page header when `isBlocked` is true |
| `site/lib/main.server.options.dart` | Regenerated (`build_runner build`) to register the new component's styles |
| `site/test/grading_test.dart` | 4 new `isBlocked` cases: red from SwiftPM, red from alignment, false when neither is red, false when a check is only amber |

## Design Notes

- **Where "red" is decided once.** `isBlocked` reuses the existing
  `swiftPmStatus`/`alignmentStatus` functions rather than re-deriving
  redness from raw fields, so a future change to either grading rule
  automatically flows through to the CTA — it can't drift out of sync the
  way two independent implementations could.
- **One CTA per blocked plugin, not per blocked check.** A plugin blocked
  by both SwiftPM and alignment gets a single CTA row/paragraph, not two.
  The SPEC's copy ("blocked by *this plugin*") is about the plugin, not a
  specific deadline.
- **Board placement.** The CTA is a full-width sub-row directly beneath
  the blocked plugin's row (`<tr class="cta-row"><td colspan="5">`) rather
  than crammed into one of the five narrow columns, so the sentence isn't
  wrapped into an unreadable ribbon.
- **Android is never a red trigger.** Android build settings have no
  colour rule yet (SPEC open decision 3), so they never contribute to
  `isBlocked` — consistent with `plugin_table.dart`'s existing comment
  that Android is "facts only."

## Automated Test Results

```
$ cd site && dart analyze --fatal-infos
Analyzing site...
No issues found!

$ dart test
00:00 +14: All tests passed!

$ dart format --output=none --set-exit-if-changed .
Formatted 19 files (0 changed) in 0.03 seconds.
```

## Build Verification

Ran the live static build on the fleetbox, in the foreground (after
prepending `/usr/lib/dart/bin` to `PATH` — `jaspr build`'s SDK-verification
step needs `which dart` to resolve directly into the SDK's `bin/`, not
through the `/usr/bin/dart` symlink):

```
$ dart run build_runner build --delete-conflicting-outputs
Built with build_runner/aot in 49s; wrote 1899 outputs.

$ PATH="/usr/lib/dart/bin:$PATH" jaspr build
...
(101/101) Generating route "/p/qr_code_scanner_plus" ...
Completed building project to /build/jaspr.
```

101 routes, 0 failures — same count as e3-s1, confirming this change
didn't break route generation.

Served the build output locally (`python3 -m http.server 8321`, avoiding
the reserved 3000/3001/4000 ports) and screenshotted with Playwright:

- `10xs/workflow/evidence/e3-s2-index-red-row.png` — the board's
  `path_provider` row (red "Blocked" SwiftPM chip) with the CTA sub-row
  directly beneath it, text and link both visible.
- `10xs/workflow/evidence/e3-s2-plugin-path_provider.png` — the
  `path_provider` plugin page with the CTA banner rendered under the page
  header, above the evidence sections.

Checked against `data/latest.json`: 11 of the 100 plugins are currently
blocked (all by SwiftPM; none by alignment in this snapshot), confirming
the CTA has real rows to attach to, not just the one screenshotted.

## Known Issues / Limitations

- No plugin in the current snapshot is blocked by 16 KB alignment, so the
  alignment-red path of `isBlocked` is exercised by the unit test but not
  by a live screenshot. The unit test (`SoFile(aligned: false)`) covers
  the logic.
- Branding/visual polish of the CTA box (border + red text) is a plain,
  accessible treatment consistent with the existing status-chip palette;
  no separate design pass was requested for this card.

## Suggested Commit Message

```
Add HireFlutter red-row call to action (e3-s2)

On any red row (board table) or red plugin page (SwiftPM or 16 KB
alignment blocked), show "Blocked by this plugin? A HireFlutter
developer can migrate or fork it." linking to https://hireflutter.dev
(SPEC §2, §3.2; architect note e3-s2).

Adds `isBlocked` to grading.dart (red on either check, shared by the
table and the plugin page so they can't disagree) and a reusable
HireFlutterCta component. The board table renders the CTA as a
full-width sub-row directly under a blocked plugin's row.

Verified with dart analyze --fatal-infos, dart test (4 new isBlocked
cases), dart format, and a full jaspr build (101 routes) served
locally and screenshotted with Playwright showing the CTA on the
path_provider board row and its plugin page.

Co-Authored-By: 10xs.ai
```
