# Completion Report: e2-s2 — Scheduling and commit

Instruction: `10xs/workflow/instructions/20260927_06_e2-s2-scheduling-and-commit.md`,
which expands the architect's note in
`10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md` (section
"e2-s2").

## Work Completed

| File | Purpose |
|---|---|
| `.github/workflows/nightly-snapshot.yml` | Daily cron (02:00 UTC) + `workflow_dispatch`. Sets up Dart, `dart pub get`s both existing packages, runs `snapshot_job/bin/snapshot.dart --top 100 --out ../../data/snapshots/`, then commits `data/` under a `github-actions[bot]` identity with a `Co-Authored-By: 10xs.ai` trailer — only when `git diff --cached` is non-empty — and pushes. `permissions: contents: write`; no secret referenced beyond the implicit default `GITHUB_TOKEN` checkout uses. |
| `.github/workflows/ci.yml` | Runs on every `push` and `pull_request`. A single step globs `packages/*/pubspec.yaml`, and for each discovered package directory runs `dart pub get`, `dart analyze --fatal-infos`, and `dart test`, capturing each package's test output to `test_output/<package>.txt`. `set -o pipefail` plus `if ! ... ; then failed=1; fi` around both the analyze call and the piped test call means one package failing doesn't stop the loop or hide the others' output; the step exits non-zero at the end if any package failed. `actions/upload-artifact@v4` with `if: always()` keeps `test_output/` even on failure. No hard-coded package list, so e4's `flutter_ready` package will be picked up without editing this file. |

Both files are new; no existing files were touched. `.github/` did not exist
before this card.

## Design Notes

- **Discovery over hard-coding:** `ci.yml` iterates `packages/*/pubspec.yaml`
  rather than naming `readiness_check`/`snapshot_job` explicitly, per the
  architect note's framing ("every package under `packages/`") and because
  e4 adds a third package later.
- **`dart test` needs the package's own working directory** (it resolves
  against the cwd's `.dart_tool/package_config.json`); `dart analyze` accepts
  a directory argument directly. The loop reflects that difference: analyze
  is called as `dart analyze --fatal-infos "$pkg_dir"`, test as `(cd
  "$pkg_dir" && dart test --reporter expanded)`.
- **`set -o pipefail` is load-bearing**, not decorative: without it, `dart
  test ... | tee file` always reports `tee`'s exit code (0) to the `if`, so a
  real test failure would silently pass. Verified locally (see below) that a
  synthetic failing command inside the same `if ! (...) | tee ...; then`
  shape does propagate to a non-zero step exit.
- **Bot identity vs. commit-attribution trailer kept separate**, per
  `TASK_WORKFLOW.md`'s "Commit Attribution" rule: the workflow sets `git
  config user.name`/`user.email` to a real `github-actions[bot]` committer
  identity (not `10xs.ai`), and carries `Co-Authored-By: 10xs.ai` only as a
  message trailer. That rule governs a connected agent's own commits in this
  repo; it doesn't forbid a CI job's runtime `git config` for its own bot
  account, which is what actually makes the commit here.
- **Commit only when something changed:** `git diff --cached --quiet` after
  `git add data/` gates the commit/push; a no-op night (e.g. every top-N
  plugin's data is byte-identical to the prior snapshot, or `generatedAt`
  aside — in practice `generatedAt` always differs, so this is really a
  belt-and-suspenders guard against a job that produced nothing) exits 0
  without pushing.
- **No extra secret:** both workflows only use the default token
  `actions/checkout` wires up implicitly for same-repo pushes; nothing named
  `secrets.*` appears in either file.

## Automated Test Results / Local Validation

No Dart test suite applies to workflow YAML. Validated instead by running,
locally on the fleetbox, the exact loop `ci.yml`'s step performs, against
both existing packages:

```
$ for pubspec in packages/*/pubspec.yaml; do ... done  # ci.yml's loop, verbatim
::group::readiness_check
...
Analyzing readiness_check...
No issues found!
00:00 +36: All tests passed!
::endgroup::
::group::snapshot_job
...
Analyzing snapshot_job...
No issues found!
00:00 +5: All tests passed!
::endgroup::
$ echo "EXIT CODE: $?"
EXIT CODE: 0
```

Failure-propagation check (does a failing piped command actually flip
`failed=1` under `pipefail`, isolated from the real loop):

```
$ bash -c 'set -eo pipefail; failed=0
if ! (false) 2>&1 | tee /tmp/out.txt; then failed=1; fi
echo "failed=$failed"; exit $failed'
failed=1
$ echo "outer exit: $?"
outer exit: 1
```

Both new YAML files parse (`yaml.safe_load`, Python) without error.
`actionlint` is not installed on this fleetbox, so no static-analysis pass
was run against the workflow files beyond syntax parsing and the manual
review against GitHub Actions' documented `dart-lang/setup-dart`,
`actions/upload-artifact@v4` and default-shell (`bash -eo pipefail`, which
is why every fallible command that must not abort the loop is wrapped in an
`if !`) semantics.

No live scheduled run exists yet (cron only fires on the repository's
default branch once merged there — GitHub does not run `schedule` triggers
on feature branches). `workflow_dispatch` gives a manual way to exercise it
after merge; that first live run is not part of this card's scope per the
architect note, which only asks for the workflow to exist and commit only
when something changed.

## Build Verification

No build step applies (YAML + a Dart CLI already built in e2-s1). The local
analyze/test loop above (exit 0) is the verification that CI's own step
would pass today.

## Known Issues / Limitations

- Neither workflow has been exercised as an actual GitHub Actions run yet —
  that requires the branch to reach GitHub and, for the cron trigger
  specifically, to reach the default branch. This report's evidence is a
  local simulation of the exact commands, not a hosted run.
- `actionlint` isn't available on the fleetbox to double check the YAML
  against the Actions schema beyond basic parsing; a careful manual read
  substituted for it.

## Suggested Commit Message

```
Add nightly-snapshot and CI GitHub Actions workflows

nightly-snapshot.yml runs the snapshot_job daily at 02:00 UTC (plus
workflow_dispatch), committing data/ under a github-actions[bot]
identity only when something changed. ci.yml runs dart analyze
--fatal-infos and dart test for every package under packages/ on push
and PR, keeping each package's test output as an artifact even when a
package fails.

Co-Authored-By: 10xs.ai
```
