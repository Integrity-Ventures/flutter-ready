# e6-s2: Golden CLI tests — completion report

Instruction: `10xs/workflow/instructions/20260927_10_e6-s2-golden-cli-tests.md`

Branch: `feature/e6-s2-golden-cli-tests`
Commit: `54a91585d7d618f9f2d88362a6f081ac09d75f64`

## Work completed

| File | Lines | Notes |
|---|---|---|
| `packages/flutter_ready/test/check_report_golden_test.dart` | 86 | New. 4 golden scenarios, loads fixture JSON, supports `UPDATE_GOLDENS=1` |
| `packages/flutter_ready/test/goldens/blocker.txt` | 4 | Data (golden) |
| `packages/flutter_ready/test/goldens/clean.txt` | 3 | Data (golden) |
| `packages/flutter_ready/test/goldens/not_checked.txt` | 4 | Data (golden) |
| `packages/flutter_ready/test/goldens/suggestion.txt` | 5 | Data (golden) |
| `fixtures/sample_app/data/latest.json` | 40 | New. schemaVersion 1 snapshot: `fixture_blocked_plugin` (red) + `fixture_green_plugin` (green) |
| `fixtures/sample_app/data/deadlines.json` | 25 | New. Copy of the repo's real `data/deadlines.json` |
| `fixtures/sample_app/data/replacements.json` | 8 | New. One synthetic, clearly-fixture-only suggestion |
| `fixtures/sample_app/pubspec.lock` | 17 | Edited. Now pins `fixture_blocked_plugin 1.0.0` instead of the real `path_provider 2.1.6` |
| `action.yml` | +19 | Edited. Adds a `report` output, capturing the check step's stdout via a `$GITHUB_OUTPUT` multiline block; existing behaviour (stdout printing, exit code) unchanged |
| `.github/workflows/verify-action.yml` | +8/-4 | Edited. Points `data:` at the fixture, asserts `steps.check.outputs.report` contains `BLOCKER: fixture_blocked_plugin` in addition to the existing `outcome == 'failure'` check |
| `10xs/workflow/instructions/20260927_10_e6-s2-golden-cli-tests.md` | — | This card's instruction |

One implementation Dart file (the golden test), within the 5-file cap;
everything else is fixture data, golden text, or CI/action config.

### Why this shape

The 2026-09-27 architect note on e5-s1 flagged that `verify-action.yml`
relied on `data/latest.json`'s real `path_provider` being red — a false
red the e2-s1 rework removes, and which the nightly job (e2-s2) overwrites
daily regardless. This card gives the verify workflow its own, stable
fixture data (`fixtures/sample_app/data/`) with a plugin that is
*permanently* red by construction (`fixture_blocked_plugin`, tag=false,
archive=false) and one that is permanently green
(`fixture_green_plugin`), then reuses that same data as the input to the
golden tests, so both the Action's CI check and the unit-level golden
suite are backed by the same, non-drifting fixture.

The note also asked for an assertion stronger than `outcome == 'failure'`
("which a failed install also satisfies"). Since a composite action step's
stdout isn't otherwise visible to a later step's conditionals, I added a
`report` output to `action.yml`, populated by capturing the check step's
stdout into `$GITHUB_OUTPUT` via the standard multiline-delimiter idiom.
This is additive — the step still prints to the log and exits non-zero
exactly as before — and it lets `verify-action.yml` assert the actual
`BLOCKER: fixture_blocked_plugin` line appears in the report text, not
just that the step failed.

## Automated test results

```
$ cd packages/flutter_ready && dart analyze --fatal-infos
Analyzing flutter_ready...
No issues found!

$ dart test --reporter compact
...
+17: All tests passed!
```

17 tests total in `packages/flutter_ready` (13 pre-existing + 4 new golden
tests: blocker, clean, not checked, suggestion). Re-ran the same
analyze+test loop across every package under `packages/` (matching
`ci.yml`'s per-package loop) to confirm no regressions elsewhere:
`readiness_check` (45 tests) and `snapshot_job` (5 tests) both still pass
with zero analyzer issues. CI already keeps `test_output/` as an artifact
(`ci.yml`, from e2-s2) — no changes needed there; SPEC §5's "test suite
must run in CI and keep its output" was already satisfied.

## Manual end-to-end verification (foreground, per the architect gate)

Ran the exact command `action.yml`'s check step runs, against this card's
new fixture data:

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
```

Also confirmed the clean path against a `fixture_green_plugin` lockfile
(not committed, built the same way as e5-s1's clean-path check):

```
$ dart pub global run flutter_ready check \
    --lockfile /tmp/e6s2_clean/pubspec.lock --data fixtures/sample_app/data/latest.json
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

No blockers found.
$ echo $?
0
```

Separately simulated `action.yml`'s new output-capture logic verbatim in
bash (capturing `dart pub global run`'s stdout into a `report` variable,
then substring-matching it) to confirm the capture-and-assert mechanism
itself works before trusting it to a GitHub Actions run:

```
$ report="$(dart pub global run flutter_ready check --lockfile fixtures/sample_app/pubspec.lock --data fixtures/sample_app/data/latest.json)"
$ echo "exit_code=$?"
exit_code=1
$ [[ "$report" == *"BLOCKER: fixture_blocked_plugin"* ]] && echo PASS
PASS
```

`action.yml` and `.github/workflows/verify-action.yml` were also checked
with `yaml.safe_load` (Python) to confirm both still parse as valid YAML
after editing.

## Known issues or limitations

- `.github/workflows/verify-action.yml` itself was not run inside a real
  GitHub Actions runner (no such environment here) — the manual foreground
  verification above runs the identical commands the action's steps run,
  against the identical fixture data, and the output-capture idiom
  (`$GITHUB_OUTPUT` multiline block) is GitHub's own documented mechanism,
  but the architect's review on the fleetbox (which does have real CI) is
  the final proof.
- The local verification run's console output includes some incidental
  `dart pub` version-check noise ("Resolving dependencies...", "1 package
  has newer versions...") ahead of the actual report text — an artifact of
  this dev box's shared global pub cache across other cards' clones
  (`flutter_ready` was already globally activated from a different lane).
  This doesn't affect correctness: the verify workflow's assertion is a
  substring match on the report text, not an exact-output comparison, and
  e5-s1's own manual verification (a fresh activate immediately before use)
  didn't show this noise.
- This card does not touch `data/latest.json`, `data/deadlines.json`, or
  `data/replacements.json` at the repo root — those are the real,
  nightly-job-owned data, out of scope here.
- Per the architect gate: this branch was pushed to this clone's local
  `origin` (`~/flutter-ready`), not to github.com. The architect moves it
  from there.

## Suggested commit message

Already used verbatim for this card's single commit:

```
Add golden CLI tests, decouple verify-action from live data (e6-s2)

Golden tests for flutter_ready check's report text, driven by a new
fixtures/sample_app/data/ snapshot with a synthetic red plugin and a
synthetic green one. Point the Action's verify workflow at that fixture
data instead of the live data/latest.json, whose real-world path_provider
red status the e2-s1 rework will remove, and which the nightly job
overwrites daily regardless. The Action now also exposes its report text
as an output so the verify workflow can assert on the actual BLOCKER line,
not just the step's outcome.

Co-Authored-By: 10xs.ai
```
