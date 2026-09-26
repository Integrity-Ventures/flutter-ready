# Microtask Instruction: e5-s1 REWORK — the Action never runs flutter_ready on GitHub (OPEN, not done)

Status: **OPEN.** Written by the architect on 2026-09-27. A worker launched
on card e5-s1 executes THIS file.

## Finding

Verify Action run 36275381660 (commit c2ed329) failed at its assertion step,
and the log shows why. Inside our composite `action.yml`, the nested
`dart-lang/setup-dart@v1` step fails:

```
##[error]Unable to process command '::add-matcher::/home/runner/work/flutter-ready/flutter-ready/./dart-analyzer.json' …
##[error]Could not find file '/home/runner/work/flutter-ready/flutter-ready/dart-analyzer.json'.
##[end-action id=check.__dart-lang_setup-dart;outcome=failure]
```

So "Install flutter_ready" and "Run flutter_ready check" are **skipped**,
and `report` is empty. The earlier green Verify Action runs (6c7162b, bc24abf)
were false passes: they asserted only `outcome == failure`, which this
setup failure satisfies. e6-s2's BLOCKER-line assertion exposed it.

## Implementation Steps

1. `action.yml`: stop the nested setup-dart step from registering its problem
   matcher. Its input is shown in the log as `problem-matcher: true`, so
   pass `problem-matcher: false`. If that input isn't honoured, install
   the Dart SDK another way inside the composite action (for example,
   download the stable SDK zip into `$RUNNER_TEMP` and add it to
   `$GITHUB_PATH`).
2. Keep `verify-action.yml`'s assertions exactly as e6-s2 left them
   (outcome failure AND the `BLOCKER: fixture_blocked_plugin` line).
3. Add a second job in `verify-action.yml` that runs the action on a
   lockfile with only `fixture_green_plugin` and asserts it **succeeds**.
   Then a broken install can never look like a pass.

## Acceptance Criteria

- You can't run GitHub Actions on the fleetbox. In your report, state
  exactly what you changed and why, and quote the setup-dart source or
  README line that documents the `problem-matcher` input, if you can find it.
- The architect merges to develop and confirms the Verify Action run on
  GitHub: both jobs must pass.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground, lane branch
  `feature/e5-s1-rework-setup-dart` pushed to the local origin, and a report at
  `10xs/workflow/task_reports/e5-s1-rework_report.md`.
