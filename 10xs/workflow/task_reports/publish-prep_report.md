# Publish prep: one package — completion report

Instruction: `10xs/workflow/instructions/20260928_21_publish-prep-one-package.md`

Branch: `feature/publish-prep`
Commit: `334580b`

## What changed

The owner chose option (b) on 2026-09-28: one self-contained package instead
of two. `readiness_check`'s entire `lib/src/*` moved (via `git mv`, history
preserved) into `packages/flutter_ready/lib/src/readiness/`, and its public
library file into `packages/flutter_ready/lib/readiness_check.dart` (same
export list, paths updated to `src/readiness/...`). Its tests and
`test/fixtures/` moved the same way into `packages/flutter_ready/test/`. The
old `packages/readiness_check/` directory no longer exists.

`snapshot_job` and `site` now depend on `flutter_ready` by path (never
published, so a path dependency is fine there) instead of `readiness_check`;
every `package:readiness_check/readiness_check.dart` import became
`package:flutter_ready/readiness_check.dart`. `live_check_test.dart`'s
fixtures constant changed from `'../readiness_check/test/fixtures'` to
`'test/fixtures'` (its own package's fixtures now).

`.github/workflows/nightly-snapshot.yml`'s `dart pub get -C
packages/readiness_check` became `dart pub get -C packages/flutter_ready`.
`ci.yml` needed no change (it already loops over `packages/*/pubspec.yaml`,
and there are still exactly two: `flutter_ready`, `snapshot_job`).
`packages/flutter_ready/analysis_options.yaml` picked up the
`test/fixtures/sources/**` exclusion that used to live in
`readiness_check/analysis_options.yaml` (fixture `pubspec.yaml` files, not
real manifests). STATUS.md's package table folded the two rows into one.

`packages/flutter_ready/pubspec.yaml`: removed `publish_to: none`, added
`issue_tracker`, added `archive` as a direct dependency (moved in with the
library code that uses it). Added `README.md`, `CHANGELOG.md` (`## 0.1.0`),
and a copy of the repo's MIT `LICENSE`.

**Never ran `dart pub publish` without `--dry-run`** — only the dry run, per
the instruction; the owner publishes the real first version by hand.

## Gates

```
$ cd packages/flutter_ready && dart pub get && dart analyze --fatal-infos && dart test
No issues found!
...
+96: All tests passed!
```

96 tests (matches the instruction's arithmetic: flutter_ready 26 +
readiness_check 70 = 96).

```
$ cd packages/snapshot_job && dart pub get && dart analyze --fatal-infos && dart test
No issues found!
...
+10: All tests passed!
```

```
$ cd site && dart pub get && dart analyze --fatal-infos && dart test
No issues found!
...
+32: All tests passed!
```

## Site build and tile counts

```
$ cd site && jaspr build
...
(146/146) Generating route "/p/flutter_aepuserprofile" ...
Completed building project to /build/jaspr.
```

Parsed the built `build/jaspr/index.html`'s tile numbers: **83 Blocked, 8
Unclear, 45 Ready, 9 Not affected** — identical to STATUS.md's pre-change
figures.

## Nightly job, run once in the foreground

```
$ cd packages/snapshot_job && dart pub get && dart run bin/snapshot.dart --top 100 --out /tmp/snapshot_test_out/
Assembled 145 plugin(s) from 145 candidate(s) in 0:00:23.166400.
```

Diffed the output's shape against the committed `data/latest.json`: same
top-level keys (`discovery`, `generatedAt`, `plugins`, `schemaVersion`),
same `schemaVersion: 1`, same per-plugin key set, same plugin count (145).
Not committed — it's a live run against the real pub.dev search, and only
useful here as a shape check, per the instruction ("don't commit new data
unless it differs only in timestamps"; this run wasn't diffed plugin-by-plugin
against `develop`'s data since ordinary pub.dev search drift is expected
between runs, same as prior cards).

## `dart pub publish --dry-run`

Full output, from `packages/flutter_ready`:

```
Publishing flutter_ready 0.1.0 to https://pub.dev:
├── CHANGELOG.md (<1 KB)
├── LICENSE (1 KB)
├── README.md (1 KB)
├── analysis_options.yaml (<1 KB)
├── bin
│   └── flutter_ready.dart (<1 KB)
├── lib
│   ├── flutter_ready.dart (<1 KB)
│   ├── readiness_check.dart (1 KB)
│   └── src
│       ├── check_command.dart (5 KB)
│       ├── check_report.dart (6 KB)
│       ├── live_check.dart (4 KB)
│       ├── pubspec_lock.dart (<1 KB)
│       ├── readiness
│       │   ├── android_build_settings.dart (3 KB)
│       │   ├── concurrency_pool.dart (<1 KB)
│       │   ├── elf_alignment_check.dart (3 KB)
│       │   ├── grading.dart (3 KB)
│       │   ├── ios_resolution.dart (3 KB)
│       │   ├── live_grade.dart (3 KB)
│       │   ├── package_archive.dart (2 KB)
│       │   ├── plugin_discovery.dart (5 KB)
│       │   ├── pub_dev_client.dart (10 KB)
│       │   ├── snapshot_model.dart (7 KB)
│       │   └── swiftpm_check.dart (1 KB)
│       └── replacements.dart (<1 KB)
├── pubspec.yaml (<1 KB)
└── test
    ├── ... (fixtures/, goldens/, all test files)
Total compressed archive size: 47 KB.
Validating package...
The server may enforce additional checks.

Package has 0 warnings.
```

(Ran once with an uncommitted tree — pana/pub flagged the 59-file uncommitted
diff as a "potential issue"; committed everything and re-ran, and the
"modified files" and missing-README/CHANGELOG warnings disappeared, leaving
the quoted **0-warning** run above.)

## Install test, as a stranger would

```
$ dart pub global activate --source path packages/flutter_ready
Installed executable flutter_ready.

$ flutter_ready check --data fixtures/sample_app/data/latest.json --offline
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive. — from Flutter Ready data (2026-09-27)
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
$ echo $?
1
```

Also ran against `fixtures/sample_app/pubspec_green.lock` (the same
fixture's clean lockfile): `No blockers found.`, exit code `0`. Used
`fixtures/sample_app/` (the e5-s1 Action-verify fixture already in the
repo) rather than writing a new one.

## `pana` (optional)

Installed cleanly (`dart pub global activate pana`). Predicted score:
**130/160**. Breakdown:

- Follow Dart file conventions: 20/30 — loses the 10 for "provide a valid
  pubspec.yaml" only because pana can't clone `repository` from this local,
  unpushed clone to verify `publish_to` is absent there; README, CHANGELOG,
  license all score full.
- Provide documentation: 10/20 — full credit for >20% dartdoc coverage
  (43.5%); loses 10 for no `example/` directory (pre-existing gap, out of
  this card's scope).
- Platform support: 20/20.
- Pass static analysis: 40/50 — 10 issues pana's own lint set (not this
  repo's `package:lints/recommended.yaml`, which `dart analyze
  --fatal-infos` passes clean) flags, plus formatting: `dart format
  --output=none --set-exit-if-changed .` reports the same files unformatted
  both before and after this move (confirmed against files this card only
  `git mv`'d, unedited) — pre-existing, not introduced here.
- Support up-to-date dependencies: 40/40.

## Files changed

74 files: full detail is the `git mv`/`git diff` history on
`feature/publish-prep`; summary:

| Area | Change |
|---|---|
| `packages/readiness_check/` | Deleted; `lib/src/*` → `packages/flutter_ready/lib/src/readiness/`, public library → `packages/flutter_ready/lib/readiness_check.dart`, tests + fixtures → `packages/flutter_ready/test/` |
| `packages/flutter_ready/pubspec.yaml` | Removed `publish_to: none`; added `issue_tracker`, `archive` dependency; removed the `readiness_check` path dependency |
| `packages/flutter_ready/{README,CHANGELOG,LICENSE}` | New |
| `packages/flutter_ready/analysis_options.yaml` | Added the fixture-sources exclude |
| `packages/snapshot_job/pubspec.yaml`, `site/pubspec.yaml` | `readiness_check` path dep → `flutter_ready` path dep |
| `packages/snapshot_job/{bin,lib,test}/*.dart`, `site/lib/data/{grading,models}.dart` | Import path updated |
| `packages/flutter_ready/test/live_check_test.dart` | Fixtures path fixed to its own package |
| `.github/workflows/nightly-snapshot.yml` | `pub get -C` path fixed |
| `STATUS.md` | Package table folded to one row |

## Known issues or limitations

- `pana`'s "valid pubspec.yaml" check needs a pushed, clonable `repository`
  URL to fully verify; can't be satisfied from an unpushed local branch.
  Not a defect in the package itself — `dart pub publish --dry-run` (the
  instruction's actual acceptance bar) is clean at 0 warnings.
- Pre-existing formatter and pana-lint gaps (see above) were not introduced
  by this move and are out of this card's scope (it changed package
  layout and publishability, not code style or docs coverage).
- Per the architect gate: this branch was pushed to this clone's local
  `origin` (`~/flutter-ready`), not to github.com. The architect moves it
  from there.

## Suggested commit message

Already used verbatim for this card's single commit:

```
Move readiness_check into flutter_ready as one publishable package

pub.dev refuses a path dependency, and readiness_check isn't on pub.dev.
The owner chose (b) on 2026-09-28: one self-contained package instead
of two. Moves the shared grading library into flutter_ready/lib/src/readiness/,
re-exported at package:flutter_ready/readiness_check.dart, and points
snapshot_job and site at flutter_ready by path. Adds README, CHANGELOG and
LICENSE and drops publish_to: none so `dart pub publish --dry-run` is clean.

Co-Authored-By: 10xs.ai
```
