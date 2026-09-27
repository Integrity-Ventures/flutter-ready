# Completion Report: e5-s1 REWORK 2 — verify-action report quoting

Instruction: `10xs/workflow/instructions/20260927_10_verify-action-report-quoting.md@3f65f3f`.

## Root cause, confirmed

Reproduced locally. `dart pub global run flutter_ready ...` (the installed
composite action's "Run flutter_ready check" step) always prints pub's own
resolution chatter to **stdout** before flutter_ready's own output, because
`packages/flutter_ready` is activated `--source path`, and a path-sourced
global package is re-resolved on every `pub global run`, even immediately
after a fresh `pub global activate`:

```
$ dart pub global run flutter_ready check --lockfile ... --data ... >out.txt 2>err.txt
$ cat out.txt
Resolving dependencies...
Downloading packages...
  lints 4.0.0 (6.1.0 available)
No dependencies would change in `/…/packages/flutter_ready`.
1 package has newer versions incompatible with dependency constraints.
Try `dart pub outdated` for more information.
Flutter Ready check — 1 hosted package(s) in pubspec.lock.
...
$ cat err.txt
(empty)
```

`verify-action.yml` then did `report="${{ steps.check.outputs.report }}"`,
so GitHub pasted this text — backticks included — straight into the bash
script before it ran, and bash executed `` `dart pub outdated` `` and
`` `/…/packages/flutter_ready` `` as command substitutions. `dart pub
outdated` run from the repo root (no `pubspec.yaml` there) exits 66, which
is exactly the failure the instruction described.

## Deviation from the instruction's suggested fix, and why

The instruction offered two options for keeping pub's chatter out of the
report. I tested the second one literally
(`dart pub global run flutter_ready 2>/dev/null` after a prior
`dart pub global activate`) and it does **not** work: as shown above, the
chatter is on stdout, not stderr, so `2>/dev/null` doesn't touch it, and a
fresh `activate` right before doesn't stop the next `run` from
re-resolving. Redirecting stderr was the only mechanical difference from
the instruction's suggestion I could test in isolation; it made no
difference.

Instead, `action.yml`'s "Install flutter_ready" step now runs
`dart pub get` in `packages/flutter_ready` and `dart compile exe
bin/flutter_ready.dart -o "$RUNNER_TEMP/flutter_ready"`, producing a
standalone native executable. "Run flutter_ready check" now invokes
`"$RUNNER_TEMP/flutter_ready"` directly — no `pub` involved at check time,
so there is no resolution step and nothing to print. This satisfies the
instruction's own stated goal ("no resolution happens at run time") more
completely than either literal option, since it removes the pub run/resolve
step from the hot path entirely rather than trying to suppress its output.

## Work Completed

- `action.yml` (+7/-2 lines): "Install flutter_ready" now does `dart pub
  get` then `dart compile exe bin/flutter_ready.dart -o
  "$RUNNER_TEMP/flutter_ready"` instead of `dart pub global activate
  --source path`. "Run flutter_ready check" invokes
  `"$RUNNER_TEMP/flutter_ready" "${args[@]}"` instead of `dart pub global
  run flutter_ready "${args[@]}"`. The output-capture heredoc and exit-code
  handling are unchanged.
- `.github/workflows/verify-action.yml` (+8/-6 lines): in both
  `fails-on-known-blocker` and `passes-on-no-blocker`, the assertion step
  now reads `steps.check.outputs.report` through `env: REPORT: ${{
  steps.check.outputs.report }}` and tests `"$REPORT"` in bash, instead of
  interpolating the report text directly into the `run:` script. GitHub
  Actions substitutes `${{ }}` expressions before the script is written to
  disk regardless of where they appear, but routing the value through the
  environment means bash receives it as a single variable's value rather
  than as script text, so nothing in the report — backticks, `$(...)`, or
  otherwise — is ever parsed as shell syntax.

## Automated Test Results

No Dart source touched (action manifest and workflow YAML only):

```
$ git status --porcelain
 M .github/workflows/verify-action.yml
 M action.yml
```

No files under `packages/` touched; no existing package's tests, files, or
behavior change.

## Manual End-to-End Verification (foreground, per the architect gate)

Ran the composite action's exact new steps, in order, against both
fixtures, then simulated the workflow's assertion scripts against the
captured report:

```
$ export RUNNER_TEMP=$(mktemp -d)
$ cd packages/flutter_ready && dart pub get && \
    dart compile exe bin/flutter_ready.dart -o "$RUNNER_TEMP/flutter_ready"
Generated: /tmp/tmp.YfzgBlJORU/flutter_ready

$ cd - && "$RUNNER_TEMP/flutter_ready" check \
    --lockfile fixtures/sample_app/pubspec.lock --data fixtures/sample_app/data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive.
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
$ echo $?
1
```

No pub chatter, no backticks — `REPORT` set to exactly this text and
checked with `[[ "$REPORT" != *"BLOCKER: fixture_blocked_plugin"* ]]`:
passes.

```
$ "$RUNNER_TEMP/flutter_ready" check \
    --lockfile fixtures/sample_app/pubspec_green.lock --data fixtures/sample_app/data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

No blockers found.
$ echo $?
0
```

`REPORT` set to this text and checked with `[[ "$REPORT" == *"BLOCKER"*
]]`: false, as required — passes.

`action.yml` and `.github/workflows/verify-action.yml` were also checked
with `yaml.safe_load` (Python) to confirm they still parse as valid YAML
after the edits.

## Known Issues / Limitations

- Unverified on real GitHub Actions infrastructure (no runner available
  here) — per the instruction's acceptance criteria, the architect's re-run
  of Verify Action on GitHub, confirming both jobs green, is the
  outstanding proof.
- The nested `dart-lang/setup-dart@v1` step's `problem-matcher: false` fix
  from the prior rework (commit d3ccd1c) is untouched and still in place;
  this rework only touches the install/run mechanism and the assertion
  quoting.
- Once e4-s3 (Publish) ships and `flutter_ready` is on pub.dev, the
  install step could go back to a version-pinned `dart pub global
  activate flutter_ready` — a hosted (non-path) global package does not
  re-resolve on every `pub global run`, so this chatter is specific to the
  current path-source install. Whether to switch back or keep the compiled
  binary (which also avoids the Dart VM's pub-run startup overhead) is an
  architect call for that later card, not this one.

## Suggested Commit Message

```
Fix e5-s1 Verify Action: compile flutter_ready to avoid pub chatter, quote report via env

Co-Authored-By: 10xs.ai
```
