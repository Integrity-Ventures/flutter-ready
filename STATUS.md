# Status

**As of 2026-09-27, `main` and `develop` are the same.** The board is live
on AWS Amplify at https://main.d1rgrd4z45pwk3.amplifyapp.com/ (app
`flutter-ready`, us-east-1, built from `main` by `amplify.yml`). The
`ready.hireflutter.dev` DNS record is the owner's to add. The CLI isn't
published to pub.dev yet.

## Built

| Path | What it is | Tests |
|---|---|---|
| `packages/readiness_check/` | Shared library: plugin discovery (two pub.dev searches by downloads: iOS plugins without SwiftPM, and top plugins), SwiftPM tag and archive check, 16 KB ELF alignment check, Android Gradle facts, shared grading | 57 |
| `packages/snapshot_job/` | Nightly job: `dart run bin/snapshot.dart --out ../../data/snapshots/` | 10 |
| `packages/flutter_ready/` | CLI: `flutter_ready check [--data <path\|url>] [--lockfile <path>]`, exits 1 on a blocker | 17 (4 goldens) |
| `site/` | The board, a static Jaspr site: blocked-count headline, count tiles, reds first by downloads, an attention filter, one page per plugin | 28 |
| `action.yml` | GitHub Action wrapper around `flutter_ready check` (compiles the CLI, fails the job on a blocker) | Verify Action workflow: green on GitHub (run 36296257946) |
| `data/` | `latest.json`, `snapshots/2026-09-27.json` (146 most-downloaded plugins: 81 blocked, 8 unclear, 45 ready, 9 not affected, 3 not checked), `deadlines.json`, `replacements.json` (empty, hand-kept) | |
| `.github/workflows/` | `ci.yml` (analyze and test every package, output kept), `verify-action.yml`, `nightly-snapshot.yml` (02:00 UTC; runs only once on `main`) | |

## Not done: held for the owner

- **DNS:** `ready.hireflutter.dev` pointing at the Amplify app (the owner adds it).
- **Publishing `flutter_ready` to pub.dev** under the `hireflutter.dev`
  publisher. It can't be undone, and the publisher must exist first.

## Known gaps

- Plugins with no native iOS code, or that don't target iOS at all (for
  example Android-only plugins with a leftover template podspec), grade
  green "Not affected". That's an architect correctness call, made
  2026-09-27 and approved by the owner.
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
