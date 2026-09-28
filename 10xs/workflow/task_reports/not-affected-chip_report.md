# Completion report: chip labels match the board tiles ("Not affected", "Unclear")

Card: `added-1dde6b68-f394-4758-a2b1-86ffd24f47bb`
Instruction: `10xs/workflow/instructions/20260928_19_not-affected-chip.md`
Lane branch: `feature/not-affected-chip`

## What changed

One shared rule now decides both the tile category and the chip label:

- `site/lib/data/board.dart`: added `categoryForStatus(Status, {bool? nativeIos})`,
  the single place a raw grading `Status` becomes a `BoardCategory`. `boardCategoryOf`
  is now `categoryForStatus(swiftPmStatus(plugin), nativeIos: plugin.swiftpm.nativeIos)`
  — same behaviour as before, just factored out so the chip can call it too.
- `site/lib/components/status_chip.dart`: `StatusChip` takes an optional `nativeIos`
  param, computes `categoryForStatus(status, nativeIos: nativeIos)`, and labels itself
  with `labelForCategory(category)` (already existed in `status_colors.dart`, used only
  by the tiles before this). Colour is unchanged — still `colorForStatus`/`bgColorForStatus`
  keyed on the raw `Status`, so "Not affected" renders in the same green as "Ready".
- `site/lib/constants/status_colors.dart`: removed `labelForStatus` (the old
  colour-only labeller that said "Caution" for amber and "Ready" for every green
  result) — it's now dead code, nothing else referenced it.
- `site/lib/pages/plugin_page.dart` and `site/lib/components/plugin_table.dart`: the
  SwiftPM chip now passes `nativeIos: plugin.swiftpm.nativeIos`. The alignment chip is
  untouched (no `nativeIos` arg → always `Status.green` → "Ready"; it has no
  "not affected" case, satisfying item 3). Amber on either chip now reads "Unclear"
  automatically, since that comes from the same `labelForCategory` map.

No grading, data, or count-tile logic changed — `boardCategoryOf` and `BoardCounts`
are unchanged in behaviour, only refactored to share the new helper.

## Tests

- Added `test/board_test.dart` group `categoryForStatus (chip labels match the board
  tiles)`:
  - path_provider's shape (green SwiftPM, `nativeIos: false`) → `categoryForStatus`
    agrees with `boardCategoryOf`, and `labelForCategory` gives "Not affected".
  - A green plugin with `nativeIos: true` → agrees with `boardCategoryOf`, label
    "Ready".
  - An amber result → agrees with `boardCategoryOf`, label "Unclear", explicitly
    asserted `isNot('Caution')`.
  - A check with no "not affected" case (`nativeIos: null`, i.e. alignment) never
    labels green as "Not affected": green → "Ready", amber → "Unclear".
- `grep -rn "Caution" site/` — no visitor-facing (or any) "Caution" text remains in
  `site/`.
- `cd site && dart analyze --fatal-infos && dart test` — 32 tests, all pass.
- `cd packages/readiness_check && dart analyze --fatal-infos && dart test` — 69 tests,
  all pass, untouched.
- `cd packages/snapshot_job && dart analyze --fatal-infos && dart test` — 10 tests,
  all pass, untouched.
- `cd packages/flutter_ready && dart analyze --fatal-infos && dart test` — 26 tests,
  all pass, untouched.
- `cd site && jaspr build` — succeeded, generated all 146 plugin routes plus `/`.

## Tile counts, before and after

Unchanged by construction (`boardCategoryOf`'s behaviour didn't change, only its
implementation was factored out). Measured from the built `index.html`, same both
before and after this change:

Blocked 82, Unclear 8, Ready 45, Not affected 9, Not checked 1 (total 145 — this
snapshot currently has 145 plugins with a `snapshot.json`, not the 146 quoted in
`STATUS.md`; that's pre-existing snapshot drift from other cards, not something this
card touched).

## Screenshots

Playwright, served the `jaspr build` output over `python3 -m http.server`, chromium,
full-page screenshots at 1280x800 and 400x800, under `10xs/workflow/evidence/`:

- `not-affected-path_provider-{1280x800,400x800}.png` — SwiftPM chip reads
  "Not affected" in green; alignment chip reads "Ready" in green (unchanged).
- `not-affected-flutter_facebook_auth-{1280x800,400x800}.png` — SwiftPM chip (amber,
  tag/archive disagree) reads "Unclear", not "Caution".
- `not-affected-index-{1280x800,400x800}.png` — the board's tile counts, matching the
  numbers quoted above.

At 400px wide none of the three pages need horizontal scroll (pre-existing from the
board-copy-polish card, unaffected by this change).

## Out of scope, not touched

Grading (`packages/readiness_check`), data files, the 16 KB alignment "not affected"
case (it doesn't have one — item 3 of the instruction), and count-tile colours/order.
