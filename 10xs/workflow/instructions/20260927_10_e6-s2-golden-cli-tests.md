# e6-s2: Golden CLI tests (architect, 2026-09-27)

Read `00_ARCHITECT_GATE.md` and the e6-s2 section of
`20260927_05_architect-notes-e2-e6.md` first. This instruction turns that
note into an executable microtask.

## Objective

Give `flutter_ready check`'s report output golden-file coverage (SPEC §5:
"Golden tests of the CLI report output"), and stop `.github/workflows/verify-action.yml`
depending on the live, nightly-changing `data/latest.json` to prove its
known-blocker case (architect review of e5-s1: `path_provider`'s red status
today is a false red the e2-s1 rework will remove, and the nightly job
overwrites `data/latest.json` daily regardless).

## Context

- e5-s1 shipped `action.yml`, `fixtures/sample_app/pubspec.lock` (pinned to
  the repo's real, live `path_provider 2.1.6`), and
  `.github/workflows/verify-action.yml`, which points `data:` at the repo's
  own committed `data/latest.json` and asserts only
  `steps.check.outcome == 'failure'`.
- e6-s1 built `packages/readiness_check/test/fixtures/`, a separate fixture
  pool for the readiness-check library's own unit tests. It explicitly left
  `fixtures/sample_app/` and `verify-action.yml` untouched, scoping that
  rework here.
- `packages/flutter_ready/test/check_report_test.dart` already unit-tests
  `buildCheckReport` with hand-built `PluginEntry` values and `contains(...)`
  assertions. This card adds golden (exact full-text) coverage on top,
  driven by on-disk fixture data shared with the Action's verify workflow —
  it does not replace or edit that existing test file.

## Implementation steps

1. Add `fixtures/sample_app/data/latest.json`: a schemaVersion 1 snapshot
   (see the contract in `20260927_05_architect-notes-e2-e6.md`) with exactly
   two synthetic plugins, `fixture_blocked_plugin` (SwiftPM tag and archive
   both `false` → red under the CocoaPods deadline) and
   `fixture_green_plugin` (tag and archive both `true`, no `.so` files →
   green), both at version `1.0.0`. `errors: []` for both, Android facts
   `null` (SPEC open decision 3 — no colour rule).
2. Add `fixtures/sample_app/data/deadlines.json`: copy of the repo's real
   `data/deadlines.json` (deadlines are hand-authored data, not
   nightly-job output, so reusing the real content keeps the fixture
   faithful without inventing new deadline text).
3. Add `fixtures/sample_app/data/replacements.json`: one synthetic,
   clearly-fixture-only entry, `{"fixture_blocked_plugin": [{"replacement":
   "fixture_green_plugin", "note": "fixture-only suggestion, for golden
   tests", "source": "fixture data, not a real suggestion"}]}` — needed so
   the golden suite has a suggestion-line case. Do not add entries here to
   the real `data/replacements.json` (e4-s2's hand-kept file is out of
   scope).
4. Rewrite `fixtures/sample_app/pubspec.lock`'s single hosted package from
   `path_provider 2.1.6` to `fixture_blocked_plugin 1.0.0`, updating its
   header comment to explain it now pins a synthetic, in-repo fixture
   instead of a real package whose real-world status can drift.
5. Point `.github/workflows/verify-action.yml`'s `data:` input at
   `fixtures/sample_app/data/latest.json`. `deadlines.json` and
   `replacements.json` are picked up automatically as siblings of `data`
   (`check_command.dart`'s `_sibling` helper).
6. Extend `action.yml`'s "Run flutter_ready check" step to also expose the
   report text as a step/action output (`report`), captured via a
   `$GITHUB_OUTPUT` multiline block, without changing its existing
   stdout-printing or exit-code behaviour. This is required so a calling
   workflow — namely `verify-action.yml` — can assert on the actual report
   text a real invocation produced, not just its exit status.
7. Update `verify-action.yml`'s assertion step to also check that
   `steps.check.outputs.report` contains `BLOCKER: fixture_blocked_plugin`,
   failing with a clear message (showing the captured report) if not. Keep
   the existing `outcome == 'failure'` check — the note's ask is "not just
   outcome == failure", i.e. add to it, not replace it.
8. Add `packages/flutter_ready/test/check_report_golden_test.dart`: load
   the three fixture JSON files from step 1–3 (path relative to the
   package root, matching `ci.yml`'s `cd "$pkg_dir" && dart test`), and
   call `buildCheckReport` four times against combinations of locked
   packages, comparing the exact `report.text` output against four golden
   files under `packages/flutter_ready/test/goldens/`:
   - `blocker.txt` — `fixture_blocked_plugin` locked, no replacements.
   - `clean.txt` — `fixture_green_plugin` locked.
   - `not_checked.txt` — an unlisted package name locked.
   - `suggestion.txt` — `fixture_blocked_plugin` locked, with the
     replacements fixture from step 3.
   Support regenerating the golden files from an environment variable
   (e.g. `UPDATE_GOLDENS=1`), so a future intentional report-format change
   doesn't require hand-editing four text files.
9. Leave `packages/flutter_ready/test/check_report_test.dart` and every
   other existing test untouched.

## File scope

- `fixtures/sample_app/data/latest.json` (new, data)
- `fixtures/sample_app/data/deadlines.json` (new, data)
- `fixtures/sample_app/data/replacements.json` (new, data)
- `fixtures/sample_app/pubspec.lock` (edit)
- `.github/workflows/verify-action.yml` (edit)
- `action.yml` (edit)
- `packages/flutter_ready/test/check_report_golden_test.dart` (new)
- `packages/flutter_ready/test/goldens/{blocker,clean,not_checked,suggestion}.txt` (new, data)

One implementation-relevant Dart file (the golden test), plus config/data
files — within the 5-implementation-file limit.

## Acceptance criteria

- `dart analyze --fatal-infos` and `dart test` pass in
  `packages/flutter_ready` with zero network calls.
- All four golden scenarios (blocker, not checked, clean, suggestion) are
  covered and pass against their golden files.
- `verify-action.yml` no longer reads `data/latest.json` or
  `data/deadlines.json`; it reads only files under `fixtures/sample_app/`.
- Manually running the same command `action.yml` runs (`dart pub global
  run flutter_ready check --lockfile fixtures/sample_app/pubspec.lock
  --data fixtures/sample_app/data/latest.json`) in the foreground exits 1
  and prints a `BLOCKER: fixture_blocked_plugin` line.
- `action.yml` still parses as valid YAML and its existing inputs/behaviour
  (default `data`, default `lockfile`) are unchanged.

## Testing strategy

- `cd packages/flutter_ready && dart analyze --fatal-infos && dart test
  --reporter expanded`, matching `ci.yml` (which already uploads
  `test_output/` as a CI artifact — SPEC §5's "test suite must run in CI
  and keep its output" is already satisfied by e2-s2's `ci.yml`; no changes
  needed there).
- Foreground manual run of the exact `action.yml` command against the new
  fixture data, capturing stdout and exit code in the completion report
  (same pattern as e5-s1's report).
- `python3 -c "import yaml; yaml.safe_load(open('action.yml'))"` and same
  for `verify-action.yml`, to confirm both still parse after editing.
