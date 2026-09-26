# Completion Report: e4-s2 — Replacement suggestions

Instruction: `10xs/workflow/instructions/20260927_08_e4-s2-replacement-suggestions.md`.

## Work Completed

- `data/replacements.json` (new, 1 line): `{}`. Hand-kept, per the
  architect note and SPEC open decision 4 ("they should never be
  generated"). This agent has no way to hand-verify a real replacement
  package — writing specific package names here would itself be
  generating suggestions, so the card ships the empty option the
  architect note allows, and builds the lookup/print path so a human can
  add real, verified entries later without touching code.
- `packages/flutter_ready/lib/src/replacements.dart` (new, 27 lines):
  `Replacement {replacement, note, source}` and `parseReplacements(String
  contents)`, parsing `{"<package>": [{"replacement": "…", "note": "…",
  "source": "…"}]}`. Pure, no IO; `note`/`source` default to `''` when
  absent.
- `packages/flutter_ready/lib/src/check_report.dart` (85 lines, was 78):
  `buildCheckReport` takes an optional `replacements` map (default `{}`).
  A blocker line now goes through a new `_blockerLine` helper that
  appends `\n    Suggested replacement: <name>` (plus ` — <note>` when
  present) for each matching entry in `replacements[locked.name]`. No
  matching entry → identical output to before this card.
- `packages/flutter_ready/lib/src/check_command.dart` (86 lines, was 74):
  reads `replacements.json` as a sibling of `--data` (same pattern as
  `deadlines.json`) via new `_readReplacements`, and passes it to
  `buildCheckReport`. A missing file or fetch failure (404, no local
  file) is caught and falls back to `{}` — not fatal, so data sources
  that predate this file, or that don't host it, still produce a report.
- `packages/flutter_ready/lib/flutter_ready.dart`: exports `Replacement`
  and `parseReplacements`.

## Automated Test Results

```
$ (cd packages/flutter_ready && dart analyze --fatal-infos && dart test -j1)
No issues found!
... 13 tests (3 replacements_test, 2 pubspec_lock_test, 8 check_report_test), All tests passed!

$ (cd packages/readiness_check && dart analyze --fatal-infos && dart test)
No issues found!
... 36 tests, All tests passed!

$ (cd site && dart analyze --fatal-infos && dart test -j1)
No issues found!
... 14 tests (grading_test.dart, unchanged), All tests passed!
```

New in `packages/flutter_ready/test/replacements_test.dart` (3 tests):
parsing a populated map, an empty `{}`, and entries missing `note`/
`source`. New in `check_report_test.dart` (2 added, existing ones kept
passing unchanged): a blocker with a matching `replacements` entry prints
the `Suggested replacement:` line; a blocker with no matching entry
prints byte-identical text to a run with no `replacements` argument at
all (the `withReplacements.text == withoutReplacements.text` assertion).

## Manual End-to-End Verification

Ran the built CLI against the repo's real `data/latest.json`, once with a
temporary `replacements.json` fixture next to it and once with that file
removed, using a lockfile pinned to the real, currently-red
`path_provider 2.1.6`:

```
$ dart run bin/flutter_ready.dart check --data /tmp/e4s2_data/latest.json --lockfile /tmp/test_pubspec.lock
# /tmp/e4s2_data/replacements.json present:
#   {"path_provider": [{"replacement": "path_provider_plus", "note": "hypothetical test fixture only", "source": "test"}]}

Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: path_provider 2.1.6: No Package.swift in the path_provider_foundation archive.
    Suggested replacement: path_provider_plus — hypothetical test fixture only
$ echo $?
1

# replacements.json removed, same command:
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: path_provider 2.1.6: No Package.swift in the path_provider_foundation archive.
$ echo $?
1
```

Confirms the suggestion prints when known, and the CLI degrades cleanly
(no crash, no suggestion line) when `replacements.json` doesn't exist —
the real, shipped `data/replacements.json` is `{}`, so today's live CLI
output is unchanged from e4-s1.

## Build Verification

`dart pub get` succeeded in `flutter_ready`, `readiness_check` and `site`;
`dart analyze --fatal-infos` is clean in all three (the two non-`flutter_ready`
packages needed a `pub get` refresh in this clone — unrelated to this
card's changes, confirmed by `git status` showing no edits there).

## Known Issues / Limitations

- `data/replacements.json` ships empty (`{}`). No real replacement
  suggestions exist yet — that's a deliberate consequence of SPEC open
  decision 4 ("never generated"), not a gap in this card's code. A human
  who hand-verifies a real alternative package can add it to
  `data/replacements.json` with no code change.
- No golden CLI tests yet (e6-s2, separate card) — this card's suggestion
  coverage is the two `check_report_test.dart` cases above, consistent
  with how e4-s1 scoped its own tests.

## Suggested Commit Message

```
Add hand-kept replacement suggestions to flutter_ready check (e4-s2)

Co-Authored-By: 10xs.ai
```
