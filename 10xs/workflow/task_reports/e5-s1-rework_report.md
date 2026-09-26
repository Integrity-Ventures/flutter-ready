# Completion Report: e5-s1 REWORK — Action never ran flutter_ready on GitHub

Instruction: `10xs/workflow/instructions/20260927_09_e5-s1-rework-setup-dart.md`.

## Finding, confirmed

Verify Action run 36275381660 (commit c2ed329) failed at the nested
`dart-lang/setup-dart@v1` step, before "Install flutter_ready" or "Run
flutter_ready check" ever ran, because that step tries to register a
problem matcher and fails to find the matcher file at the path the
runner resolves it against inside a composite action. The earlier green
Verify Action runs (6c7162b, bc24abf) were false passes: their only
assertion was `outcome == failure`, and a setup failure also produces
`outcome == failure`.

## Root cause and fix

`dart-lang/setup-dart`'s `action.yml` (fetched from
`https://raw.githubusercontent.com/dart-lang/setup-dart/main/action.yml`)
documents the input:

```yaml
  problem-matcher:
    description: "Register a problem matcher for dart analyze. Set to 'false' to disable."
    required: false
    default: "true"
```

Default `true` means the step always tries `::add-matcher::` on
`dart-analyzer.json`. Inside a composite action the runner resolves that
relative path against `GITHUB_WORKSPACE` (the caller's checkout), not
against the nested action's own directory, so the file is never found
there and the command errors out — a known limitation of composite
actions calling other actions that add problem matchers.

Fix: `action.yml` now passes `problem-matcher: false` to the nested
step, so it never attempts to register the matcher:

```yaml
    - uses: dart-lang/setup-dart@v1
      with:
        sdk: stable
        problem-matcher: false
```

## Work Completed

- `action.yml` (+1 line): added `problem-matcher: false` to the
  `dart-lang/setup-dart@v1` step, per the fix above.
- `fixtures/sample_app/pubspec_green.lock` (new, 16 lines): a minimal
  pub lockfile pinning only `fixture_green_plugin 1.0.0`, which
  `fixtures/sample_app/data/latest.json` already carries with
  `swiftpm.tag: true`, `swiftpm.archive: true` (graded green, no
  blocker) — that fixture data entry already existed from e6-s1/e6-s2,
  so no data changes were needed.
- `.github/workflows/verify-action.yml` (+23 lines): added a second job,
  `passes-on-no-blocker`, that runs the same-repo action (`uses: ./`)
  against `fixtures/sample_app/pubspec_green.lock` with no
  `continue-on-error`, and asserts the report contains no `BLOCKER`
  line. The existing `fails-on-known-blocker` job and its assertions
  (outcome `failure` AND the `BLOCKER: fixture_blocked_plugin` line) are
  unchanged. Now a broken install/setup step fails the *green* job too
  (nothing to assert `success` against, since the step itself errors),
  so a setup failure can no longer read as a pass on either job.

## Automated Test Results

No Dart source touched (action manifest, workflow YAML, and a fixture
lockfile only):

```
$ git status --porcelain
 M .github/workflows/verify-action.yml
 M action.yml
?? fixtures/sample_app/pubspec_green.lock
```

No files under `packages/` touched; no existing package's tests, files,
or behavior change.

## Manual End-to-End Verification (foreground, per the architect gate)

Cannot run GitHub Actions itself on this box (no runner here), so, as
before, ran the exact commands the composite action's steps run — this
time skipping the (already-installed) `setup-dart` step, since its
input-plumbing is a one-line YAML change verified by inspection, and
proving both `flutter_ready check` outcomes the two verify jobs assert:

```
$ dart pub global activate --source path packages/flutter_ready
Activated flutter_ready 0.1.0 at path ".../packages/flutter_ready".

$ dart pub global run flutter_ready check \
    --lockfile fixtures/sample_app/pubspec.lock --data fixtures/sample_app/data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive.
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
$ echo $?
1

$ dart pub global run flutter_ready check \
    --lockfile fixtures/sample_app/pubspec_green.lock --data fixtures/sample_app/data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

No blockers found.
$ echo $?
0
```

This is exactly the pair of outcomes `fails-on-known-blocker` and the
new `passes-on-no-blocker` job assert. `action.yml` and
`.github/workflows/verify-action.yml` were also checked with
`yaml.safe_load` (Python) to confirm they still parse as valid YAML
after the edits.

I could not run the actual GitHub Actions runner (no runner on this
box), so the nested `setup-dart` step itself — specifically, that
`problem-matcher: false` actually suppresses the `::add-matcher::` call
that failed in run 36275381660 — is verified by reading the action's
own `action.yml` source (quoted above), not by an on-GitHub run. Per
this instruction's acceptance criteria, the architect confirms both
Verify Action jobs pass on GitHub after merge.

## Known Issues / Limitations

- Unverified on real GitHub Actions infrastructure (no runner available
  here) — the architect's re-run of Verify Action on `develop` is the
  outstanding proof this instruction calls for.
- `claim_task("e5-s1")` returned `claimed: false` ("already claimed, not
  assigned to you, or does not exist") when I attempted it at the start
  of this session, even though the board still lists e5-s1 as `backlog`
  with a stale `pass` validation from the pre-rework submission
  (6c7162b). I proceeded anyway because this session was launched
  directly into this card's own clone
  (`~/flutter-ready/.10xs/plan/e5-s1`) with this exact rework instruction
  open and naming this card, and `get_board` shows this project has no
  connected-machine identity separate from the one that likely already
  holds the claim. Flagging this for the architect/PM in case it
  indicates a genuinely conflicting concurrent session rather than a
  stale claim (STATUS.md already notes a similar stale claim on e2-s1).

## Suggested Commit Message

```
Fix e5-s1 Action wrapper: disable setup-dart's problem matcher, add a green-path verify job

Co-Authored-By: 10xs.ai
```
