# Status

**As of 2026-09-27, on branch `develop`. `main` holds only the documents
until the owner merges.** Built and tested, but not deployed or published.

## Built (on `develop`)

| Path | What it is | Tests |
|---|---|---|
| `packages/readiness_check/` | Shared library: plugin discovery (top N after the `is:plugin` filter), SwiftPM tag and archive check, 16 KB ELF alignment check, Android Gradle facts, shared grading | 45 |
| `packages/snapshot_job/` | Nightly job: `dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/` | 5 |
| `packages/flutter_ready/` | CLI: `flutter_ready check [--data <path\|url>] [--lockfile <path>]`, exits 1 on a blocker | 17 (4 goldens) |
| `site/` | The board, a static Jaspr site: `jaspr build` → `build/jaspr/` (index plus one page per plugin) | 14 |
| `action.yml` | GitHub Action wrapper around `flutter_ready check`. It runs on GitHub, but the Verify Action assertions are red; see Known gaps | Verify Action workflow (red) |
| `data/` | `latest.json`, `snapshots/2026-09-26.json` (a real top 100 run), `deadlines.json`, `replacements.json` (empty, hand-kept) | |
| `.github/workflows/` | `ci.yml` (analyze and test every package, output kept), `verify-action.yml`, `nightly-snapshot.yml` (02:00 UTC; runs only once on `main`) | |

## Not done: held for the owner

- **Deployment** (Amplify plus the `ready.hireflutter.dev` DNS record), SPEC
  open decision 5.
- **Publishing `flutter_ready` to pub.dev** under the `hireflutter.dev`
  publisher. It can't be undone, and the publisher must exist first.

## Known gaps

- **The Verify Action workflow is red.** The action itself works on GitHub
  (run 36275890556: the blocked fixture prints its BLOCKER line and exits 1).
  The assertion steps exit 66, because the report is pasted into bash and
  pub's output contains backticks. The fix is in
  `10xs/workflow/instructions/20260927_10_verify-action-report-quoting.md`.

- **The 2026-09-26 data has two false results.** `path_provider` shows red
  (its iOS package has no native iOS code, so it isn't affected), and
  `flutter_keyboard_visibility` shows amber (the job checked its macOS
  package). The fix is written up in
  `10xs/workflow/instructions/20260927_07_e2-s1-rework-ios-resolution.md`.
  It waits on a stale 10xs claim on card e2-s1.
- No top-100 plugin ships a `.so` inside its pub.dev archive, so the 16 KB
  column is all green "no native libs in archive". SPEC §4 already says v1
  only sees archive-shipped libraries.
- Android columns are facts only, with no colour (SPEC open decision 3).

## Try it

```sh
cd packages/flutter_ready && dart pub get
cd /path/to/your/app && dart run <repo>/packages/flutter_ready/bin/flutter_ready.dart check \
  --data <repo>/data/latest.json
cd <repo>/site && dart pub global activate jaspr_cli && jaspr build   # then serve build/jaspr/
```

Jaspr needs the Dart SDK's own `bin` directory first on `PATH` (not a
`/usr/bin/dart` symlink).
