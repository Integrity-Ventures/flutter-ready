# Microtask Instruction: e4-s2 — Replacement suggestions

Written by the connected agent acting as architect, 2026-09-27, following
`00_ARCHITECT_GATE.md` and the e4-s2 section of
`20260927_05_architect-notes-e2-e6.md`.

## Objective

`flutter_ready check` prints a suggested replacement package under each
blocker, where one is known (SPEC §3.3). The source of suggestions is
unresolved (SPEC open decision 4): hand-curated, never generated.

## Context

- `packages/flutter_ready` already has `check_report.dart`
  (`buildCheckReport`) and `check_command.dart` from e4-s1. Blockers are
  grouped by deadline, one line per blocked `name version: evidence`.
- The architect note fixes the shape: `data/replacements.json`, hand-kept,
  `{"<package>": [{"replacement": "…", "note": "…", "source": "…"}]}`.
  Ship it empty (`{}`), or with at most 2 entries marked `"seed": true`
  that were verified by hand. **This agent has no way to hand-verify a
  real-world replacement package (that requires a human actually trying
  the fork/alternative) — writing specific package names in here would be
  generating suggestions, exactly what SPEC open decision 4 forbids. So
  this card ships `data/replacements.json` as `{}`** and builds the
  lookup/print path so a human can add real entries later without touching
  code.
- Nothing in `readiness_check` needs to change — replacements are a
  CLI-only concept (SPEC §3.3 scopes them to the CLI report), not part of
  the shared readiness data or the board.

## Implementation Steps

1. **`data/replacements.json`** (new, hand-kept data file): `{}`.
2. **`packages/flutter_ready/lib/src/replacements.dart`** (new):
   - `Replacement {replacement, note, source}` (all `String`, `note` and
     `source` default to `''` if absent).
   - `Map<String, List<Replacement>> parseReplacements(String contents)`:
     parses the `{"<package>": [{...}]}` shape above. An absent or empty
     JSON object parses to `{}`. Pure, no IO.
3. **`packages/flutter_ready/lib/src/check_report.dart`**: add an optional
   `Map<String, List<Replacement>> replacements = const {}` parameter to
   `buildCheckReport`. When a locked package produces a blocker line,
   look up `replacements[locked.name]`; if it has entries, append one
   `\n    Suggested replacement: <replacement>` line per entry (plus
   ` — <note>` when `note` is non-empty) to that blocker's line, so it
   prints indented under the `BLOCKER:` line. No match → no change to
   today's output.
4. **`packages/flutter_ready/lib/src/check_command.dart`**: read
   `replacements.json` as a sibling of the data source (reuse the
   existing `_sibling` helper, same pattern as `deadlines.json`) and pass
   the parsed map to `buildCheckReport`. Missing file or a fetch error
   (404, no local file) is not fatal — fall back to `{}` so a data source
   that predates this card, or one hosted without the file, still works.
5. **`packages/flutter_ready/lib/flutter_ready.dart`**: export
   `Replacement` and `parseReplacements`.
6. **Tests** (not counted against the file-count limit):
   - `packages/flutter_ready/test/replacements_test.dart`: parses a
     populated map, an empty `{}`, and entries missing `note`/`source`.
   - `packages/flutter_ready/test/check_report_test.dart`: add a case
     where a blocker's package has a matching entry in `replacements` and
     the printed report contains the `Suggested replacement:` line with
     the replacement name; and a case confirming a blocker with no
     matching entry is unchanged from before this card.

## File Scope

- `data/replacements.json` (new)
- `packages/flutter_ready/lib/src/replacements.dart` (new)
- `packages/flutter_ready/lib/src/check_report.dart`
- `packages/flutter_ready/lib/src/check_command.dart`
- `packages/flutter_ready/lib/flutter_ready.dart`
- `packages/flutter_ready/test/**` (new/modified tests)

## Acceptance Criteria

- `dart analyze --fatal-infos` and `dart test` pass, offline, in
  `packages/flutter_ready`.
- `data/replacements.json` exists and is `{}` — no generated suggestions
  committed.
- A blocker whose package has a `replacements.json` entry prints a
  `Suggested replacement:` line under that blocker; a blocker with no
  entry prints exactly as it did before this card (verified by the
  existing e4-s1 tests still passing unchanged).
- `flutter_ready check` does not fail when `replacements.json` is missing
  or unfetchable (backward compatible with data sources that predate it).

## Testing Strategy

Unit tests only, offline. `check_report_test.dart` exercises
`buildCheckReport` directly with an in-memory `replacements` map — no
network, no dependency on the real (empty) `data/replacements.json`.
