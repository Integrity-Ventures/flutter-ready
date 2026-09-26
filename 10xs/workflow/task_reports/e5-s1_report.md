# Completion Report: e5-s1 — Action wrapper

Instruction: `10xs/workflow/instructions/20260926_09_e5-s1-action-wrapper.md`.

## Work Completed

- `action.yml` (new, repo root, 32 lines): a composite GitHub Action.
  Inputs `lockfile` (default `pubspec.lock`) and `data` (default `''`,
  meaning: don't pass `--data`, so consumers get `flutter_ready check`'s
  own default of the live `main`-branch data unless they override it).
  Steps: `dart-lang/setup-dart@v1` (`sdk: stable`), then
  `dart pub global activate --source path "${{ github.action_path
  }}/packages/flutter_ready"`, then `dart pub global run flutter_ready
  check --lockfile <input>` (`--data <input>` appended only when set).
  `flutter_ready check` exits 1 on a blocker and 2 on a missing lockfile;
  either fails the step (and the job) with no extra `exit` handling.
- `fixtures/sample_app/pubspec.lock` (new, 16 lines): a minimal, valid
  pub lockfile with one hosted package, `path_provider 2.1.6` — the same
  package and version that is genuinely graded red in the repo's
  committed `data/latest.json` today (`swiftpm.tag: false`, `swiftpm.
  archive: false`, so `readiness_check`'s `swiftPmStatus` returns
  `Status.red`: no `Package.swift` in the `path_provider_foundation`
  archive). This is real data, not synthesized, and it's the same
  package e4-s2's manual verification used.
- `.github/workflows/verify-action.yml` (new, 24 lines): runs on
  `push`/`pull_request`. Checks out the repo, runs this same-repo action
  (`uses: ./`) with `lockfile: fixtures/sample_app/pubspec.lock` and
  `data: data/latest.json` (the repo's own committed snapshot, so the
  nightly job, e2-s2, updating `main`'s live data over time can't
  silently break this check), with `continue-on-error: true` and `id:
  check`. A second step asserts `steps.check.outcome == 'failure'` and
  fails the job otherwise — this workflow's job passes only when the
  action *does* fail on the known blocker, per SPEC §6 ("The Action runs
  on a sample app repo and fails on a known blocker").
- `.gitignore`: added `!/fixtures/sample_app/pubspec.lock` above the
  blanket `pubspec.lock` ignore rule (this repo is a set of packages, so
  package lock files aren't committed — but a fixture *app*'s lock file
  is meant to be committed, since it's the input the verify workflow
  checks against, not a package's own resolution).

## Automated Test Results

No Dart source shipped by this card (action manifest, workflow YAML, and
a fixture lockfile only), so no new unit tests. Confirmed no existing
package is affected:

```
$ git status --porcelain
A  .github/workflows/verify-action.yml
M  .gitignore
A  10xs/workflow/instructions/20260926_09_e5-s1-action-wrapper.md
A  action.yml
A  fixtures/sample_app/pubspec.lock
```

No files under `packages/` touched.

## Manual End-to-End Verification (foreground, per the architect gate)

Ran the exact commands the composite action's steps run, against this
card's fixture and the repo's real, committed `data/latest.json`:

```
$ dart pub global activate --source path packages/flutter_ready
Installed executable flutter_ready.
Activated flutter_ready 0.1.0 at path ".../packages/flutter_ready".

$ dart pub global run flutter_ready check \
    --lockfile fixtures/sample_app/pubspec.lock --data data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: path_provider 2.1.6: No Package.swift in the path_provider_foundation archive.
$ echo $?
1
```

Confirms the action's real failure path with today's real data — this is
the same proof `.github/workflows/verify-action.yml` runs in CI on every
push, asserting the step's `outcome` is `failure`.

Also confirmed the clean path (no blocker) still exits 0, using a
`shared_preferences 2.5.5` fixture lockfile (green in `data/latest.json`:
`swiftpm.tag: true`, `swiftpm.archive: true`) built the same way but not
committed to the repo — the fixture this card ships is deliberately the
*red* case, since that's what SPEC §6 and the architect note ask this
card to prove:

```
$ dart pub global run flutter_ready check \
    --lockfile /tmp/e5s1_clean/pubspec.lock --data data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

No blockers found.
$ echo $?
0
```

`action.yml`, `.github/workflows/verify-action.yml`, and
`fixtures/sample_app/pubspec.lock` were also checked with
`yaml.safe_load` (Python) to confirm they parse as valid YAML.

## Known Issues / Limitations

- No external sample app repo — per the architect note, this card's
  fixture and verify workflow live in this same repo. e4-s3 (Publish)
  is still blocked, so `action.yml` installs from
  `packages/flutter_ready` by path rather than from pub.dev; once e4-s3
  ships, `action.yml`'s install step can switch to a version-pinned
  `dart pub global activate flutter_ready`.
- `.github/workflows/verify-action.yml` proves the failure case; it does
  not separately assert the clean/no-blocker case (SPEC §6 asks only for
  the failing case — "fails on a known blocker" — and the clean case is
  already covered by e4-s1's own tests and this report's manual run
  above).

## Suggested Commit Message

```
Add GitHub Action wrapper for flutter_ready check (e5-s1)

Co-Authored-By: 10xs.ai
```
