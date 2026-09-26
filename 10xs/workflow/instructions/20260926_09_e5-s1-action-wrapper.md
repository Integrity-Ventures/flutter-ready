# Microtask Instruction: e5-s1 — Action wrapper

Written by the connected agent acting as architect, 2026-09-26, following
`00_ARCHITECT_GATE.md` and the e5-s1 section of
`20260927_05_architect-notes-e2-e6.md`.

## Objective

Ship a thin GitHub Action wrapper around `flutter_ready check` that fails
the job on blockers (SPEC §3.4), and prove it fails on a known blocker
(SPEC §6: "The Action runs on a sample app repo and fails on a known
blocker").

## Context

- `packages/flutter_ready` (e4-s1, e4-s2) already builds a working `check`
  command: reads a `pubspec.lock`, fetches readiness data (default: this
  repo's `main` branch `data/latest.json`), prints a report, and exits 1
  when any blocker is found, 2 when the lockfile is missing.
- The architect note fixes the shape for this card: a composite action in
  `action.yml` at the repo root that sets up Dart, runs
  `dart pub global activate --source path packages/flutter_ready` (until
  the package is published — e4-s3, still blocked), then runs
  `flutter_ready check`, and fails on exit 1. Verify with a workflow in
  *this* repo against a fixture app `pubspec.lock` holding a known
  blocker; it must fail. No external sample repo tonight.
- A real, live blocker already exists in the committed `data/latest.json`:
  `path_provider 2.1.6` has `swiftpm.tag: false` and `swiftpm.archive:
  false`, which `readiness_check`'s `swiftPmStatus` grades `Status.red`
  (no `Package.swift` in the `path_provider_foundation` archive) — this is
  the same fixture package e4-s2's manual verification used. Pinning the
  fixture lockfile to that exact version keeps the demonstration real
  (not synthesized data) while pointing `--data` at the repo's own
  committed `data/latest.json` (not the live `main` URL) so the nightly
  snapshot job (e2-s2) updating that file over time can't silently break
  this verification.

## Implementation Steps

1. **`action.yml`** (new, repo root): composite action.
   - Inputs: `lockfile` (default `pubspec.lock`), `data` (default: unset —
     when unset, don't pass `--data` to the CLI, so consumers get the
     CLI's own default of the live `main` data unless they override it).
   - Steps: `dart-lang/setup-dart@v1` (`sdk: stable`), then
     `dart pub global activate --source path ${{ github.action_path }}/packages/flutter_ready`,
     then run `flutter_ready check --lockfile <input>` (plus `--data
     <input>` only when the `data` input is non-empty). All `shell: bash`.
     `dart pub global run flutter_ready check ...` exits non-zero on a
     blocker (2 for a missing lockfile too), which fails the composite
     action's step and therefore the job — no extra `exit` handling
     needed.
2. **`fixtures/sample_app/pubspec.lock`** (new): a minimal, valid pub
   lockfile with one hosted package, `path_provider 2.1.6` — the real,
   currently-red entry in `data/latest.json` described above.
3. **`.github/workflows/verify-action.yml`** (new): a workflow, triggered
   on `push`/`pull_request` like `ci.yml`, that:
   - Checks out the repo.
   - Runs this same-repo action (`uses: ./`) with `lockfile:
     fixtures/sample_app/pubspec.lock` and `data: data/latest.json` (the
     repo's own committed snapshot, not the live URL), with
     `continue-on-error: true` and an `id` so the outcome can be read.
   - Asserts that step's `outcome` was `failure`; if it was anything else,
     the verification job itself fails (the point of this workflow is to
     prove the action *does* fail on a known blocker — a green run here
     is a regression, not a pass).

## File Scope

- `action.yml` (new)
- `fixtures/sample_app/pubspec.lock` (new)
- `.github/workflows/verify-action.yml` (new)

## Acceptance Criteria

- `action.yml` is a valid composite action that installs `flutter_ready`
  from this repo's own `packages/flutter_ready` and runs `check`.
- Running the action locally (simulating the composite steps by hand)
  against `fixtures/sample_app/pubspec.lock` and the repo's
  `data/latest.json` exits non-zero and prints the `path_provider`
  blocker.
- `.github/workflows/verify-action.yml` is added so CI itself proves the
  failure case (SPEC §6); its job fails if the action does *not* fail on
  the fixture.
- No existing package's tests, files, or behavior change.

## Testing Strategy

No Dart unit tests — this card ships no Dart source, only an action
manifest, a workflow, and a fixture lockfile. Verification is a manual,
foreground, end-to-end run of the same commands the composite action
runs (`dart pub global activate --source path packages/flutter_ready`,
then `flutter_ready check --lockfile fixtures/sample_app/pubspec.lock
--data data/latest.json`), captured with its exit code in the completion
report, plus the new `verify-action.yml` workflow that runs the same
proof in CI on every push.
