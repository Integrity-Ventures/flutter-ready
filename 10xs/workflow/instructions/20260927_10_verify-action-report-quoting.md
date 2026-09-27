# Microtask Instruction: e5-s1 REWORK 2 — verify-action report quoting (OPEN, not done)

Status: **OPEN.** The owner approved a third run of card e5-s1 on 2026-09-27. A worker launched on card e5-s1 executes THIS file. Use the lane branch `feature/e5-s1-rework-report-quoting` and write a report at `10xs/workflow/task_reports/e5-s1-rework2_report.md`. Previously parked: Written by the architect on 2026-09-27. Card e5-s1
was parked after its second failure on GitHub, per the acting PM's rule
(park after two fails, never hand-fix). This file is the exact fix for the
next run.

## State after d3ccd1c (e5-s1 rework)

- The rework's own fix works: `problem-matcher: false` makes the nested
  setup-dart step succeed. Verify Action run
  https://github.com/Integrity-Ventures/flutter-ready/actions/runs/36275890556
  now really runs `flutter_ready check` on GitHub. The blocked fixture prints
  `BLOCKER: fixture_blocked_plugin 1.0.0: …` and exits 1; the green fixture
  prints `No blockers found.`
- Both **assertion** steps still fail, with exit code 66.

## Root cause

1. `verify-action.yml` does `report="${{ steps.check.outputs.report }}"`, so
   GitHub pastes the report text into the bash script before it runs.
2. The report captures `dart pub global run`'s resolution chatter, and that
   chatter contains backticks: ``No dependencies would change in `/…/packages/flutter_ready`.``
   and ``Try `dart pub outdated` for more information.`` Bash runs them as
   command substitutions. `dart pub outdated` in the repo root fails with
   "Found no pubspec.yaml" and exit code 66.

## Fix

1. `.github/workflows/verify-action.yml`, in both jobs: pass the output
   through the environment, never inline:
   ```yaml
   - name: Assert …
     env:
       REPORT: ${{ steps.check.outputs.report }}
     run: |
       if [[ "$REPORT" != *"BLOCKER: fixture_blocked_plugin"* ]]; then …
   ```
2. `action.yml`: keep pub's chatter out of the report. Capture only
   flutter_ready's stdout after installing with `dart pub global activate`
   (its output goes to the log, not the report), or run the installed
   executable directly
   (`"$PUB_CACHE/bin/flutter_ready"` / `dart pub global run flutter_ready 2>/dev/null`
   combined with `dart pub global activate` beforehand, so no resolution
   happens at run time).
3. Accept only after the Verify Action run on GitHub shows **both** jobs
   green: `fails-on-known-blocker` and `passes-on-no-blocker`.
