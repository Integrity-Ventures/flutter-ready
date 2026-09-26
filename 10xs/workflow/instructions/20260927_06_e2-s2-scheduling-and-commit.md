# Microtask Instruction: e2-s2 — Scheduling and commit

## Objective

Wire the `snapshot_job` package into a scheduled GitHub Actions workflow that
runs nightly, commits its output into `data/`, and add a CI workflow that
runs `dart analyze` and `dart test` for every package under `packages/` on
push and PR.

## Context

- Builds on e2-s1 (`develop` at `af95c9f`): `packages/snapshot_job/bin/snapshot.dart
  --top N --out data/snapshots/` already assembles one dated snapshot plus
  `data/latest.json` and exits non-zero on... actually never mind exit codes,
  the job doesn't have a documented non-zero-on-partial-failure behaviour
  (SPEC §3.1.3 only requires per-plugin error isolation, not job failure).
- Architect note (`20260927_05_architect-notes-e2-e6.md`, section "e2-s2"):
  - `.github/workflows/nightly-snapshot.yml`: daily cron (02:00 UTC) plus
    `workflow_dispatch`. Set up Dart, run the job, commit `data/` with a bot
    identity and message trailer `Co-Authored-By: 10xs.ai`. Use
    `permissions: contents: write`, commit only when something changed, and
    target the default branch.
  - `.github/workflows/ci.yml`: `dart analyze --fatal-infos` and `dart test`
    for every package under `packages/`, on push and PR, keeping the test
    output as an artifact (SPEC §5).
  - The workflow must not need any secret beyond the built-in `GITHUB_TOKEN`.
- No `.github/` directory exists yet in this repo.
- Both existing packages (`readiness_check`, `snapshot_job`) declare
  `sdk: ^3.13.0`; the fleetbox's own `dart --version` is 3.13.4 stable, so
  `dart-lang/setup-dart` with `sdk: stable` matches.
- CI must discover packages under `packages/` rather than hard-code the two
  that exist today, since e4 adds a third package (`flutter_ready`) later
  and this workflow should not need editing for that.
- The commit-message trailer rule (`TASK_WORKFLOW.md`, "Commit Attribution")
  is about this session's own commits into this repo. It does not forbid the
  *workflow's* runtime `git config user.name`/`user.email` for its own bot
  commit identity — that identity is a real committer account
  (`github-actions[bot]`), separate from the `Co-Authored-By: 10xs.ai`
  trailer the commit message also carries.

## Implementation Steps

1. `.github/workflows/nightly-snapshot.yml`:
   - `on: schedule: [{cron: '0 2 * * *'}]` plus `on: workflow_dispatch: {}`.
   - `permissions: contents: write`.
   - Steps: checkout, `dart-lang/setup-dart@v1` (`sdk: stable`), `dart pub
     get` in both `packages/readiness_check` and `packages/snapshot_job`,
     run `dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/`
     from `packages/snapshot_job`, then a commit step that:
     - sets `git config user.name`/`user.email` to a `github-actions[bot]`
       identity (not `10xs.ai` — that stays a trailer only),
     - `git add data/`,
     - checks `git diff --cached --quiet`; if nothing changed, skips the
       commit and push (exit 0, no-op),
     - otherwise commits with a message ending
       `Co-Authored-By: 10xs.ai` and `git push`.
   - No secret beyond `${{ secrets.GITHUB_TOKEN }}` (implicit via checkout's
     default token) is referenced.
2. `.github/workflows/ci.yml`:
   - `on: [push, pull_request]`.
   - One job that: checks out, sets up Dart (`stable`), then a single shell
     step that globs every `packages/*/pubspec.yaml`, and for each package
     directory runs `dart pub get`, `dart analyze --fatal-infos`, and
     `dart test` -- capturing each package's `dart test` output to a file
     under a `test_output/` directory (`test_output/<package>.txt`), and
     failing the step (non-zero exit) if any package's analyze or test
     fails, after all packages have been attempted (don't stop at the first
     failing package, so one broken package doesn't hide another's report).
   - `actions/upload-artifact@v4` for `test_output/`, `if: always()` so the
     artifact is kept even when a package failed.

## File Scope

Implementation (2 files, well under the 5-file limit):
- `.github/workflows/nightly-snapshot.yml`
- `.github/workflows/ci.yml`

No test files apply to CI/workflow YAML; validation is `actionlint` if
available, otherwise a careful read plus a local dry run of the analyze/test
loop.

## Acceptance Criteria

- `nightly-snapshot.yml` runs on a daily cron at 02:00 UTC and on
  `workflow_dispatch`, needs only the built-in `GITHUB_TOKEN`, commits
  `data/` only when something changed, and the commit message carries
  `Co-Authored-By: 10xs.ai`.
- `ci.yml` runs `dart analyze --fatal-infos` and `dart test` for every
  package directory under `packages/` (discovered, not hard-coded), on push
  and pull request, and uploads the captured test output as a build
  artifact even when a package fails.
- Locally on the fleetbox, the same analyze/test loop the CI step runs
  passes for both existing packages.

## Testing Strategy

No Dart test suite applies to workflow YAML. Validate by:
- Running the exact `dart analyze --fatal-infos` / `dart test` loop the
  `ci.yml` step performs, locally, against both existing packages, and
  confirming it captures output per package.
- If `actionlint` is available on the fleetbox, run it against both new
  workflow files; otherwise note its absence in the report.
