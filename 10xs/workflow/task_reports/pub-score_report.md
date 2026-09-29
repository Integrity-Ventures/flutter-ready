# Full pub.dev score (160/160) and prep 0.1.1 — completion report

Instruction: `10xs/workflow/instructions/20260929_24_pub-score-160.md`

Branch: `feature/pub-score`
Commits: `993613d`, `a2b3f02`

## What changed

pub.dev scored `flutter_ready` 0.1.0 at 140/160: 0/10 for "no example
found", and one `dart analyze` INFO (`Angle brackets will be interpreted as
HTML`) inside `replacements.dart`'s two-line doc comment.

1. Added `packages/flutter_ready/example/README.md`: install, `check`
   usage, `--lockfile`/`--offline`, real output for both a blocked and a
   clean run (against `fixtures/sample_app/pubspec.lock` and
   `pubspec_green.lock`, re-run fresh rather than copied from the main
   README), the two exit codes, and a minimal GitHub Action snippet using
   the repo's own composite action.
2. Rewrote the `parseReplacements` doc comment in
   `lib/src/replacements.dart` as a fenced ` ```json ` block instead of an
   inline-code span that broke across two lines (the actual cause of the
   `<package>` text leaking as unclosed HTML). Searched the rest of `lib/`
   for the same pattern (`grep -rn '^\s*///.*<' lib/`) — every other
   `<...>` in a doc comment opens and closes its backtick on the same
   line, so no other file had this issue.
3. Bumped `version: 0.1.1` in `pubspec.yaml`; added a `## 0.1.1` entry to
   `CHANGELOG.md` ("Add an example; fix a doc comment flagged by pub.dev
   analysis. No behaviour change.").
4. Running `pana` after (1)-(3) still showed 150/160: static analysis was
   still 40/50, not from an analyzer issue (`dart analyze --fatal-infos`
   was already clean) but from `dart format --set-exit-if-changed`, which
   pana runs as part of the same score line. 9 `lib/` files predate the
   SDK's current formatter style and were unformatted before this card
   (confirmed via `git stash` + re-run — the drift exists on `develop` too,
   this Dart SDK just wasn't used to check it before). Ran `dart format .`
   and kept only the 9 `lib/` files it changed — reverted the 9 `test/`
   files it also touched, since pana's format check (like its dartdoc and
   dependency checks) only scores `lib/`+`bin/`, and reformatting untouched
   test files wasn't part of this card's brief. No behaviour change; `dart
   analyze --fatal-infos` and all 96 tests still pass after the reformat.

**Never ran `dart pub publish`** — only `--dry-run`, per the instruction.

## Gates

```
$ cd packages/flutter_ready && dart analyze --fatal-infos && dart test
No issues found!
...
+96: All tests passed!
```

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
+36: All tests passed!
```

## `dart pub publish --dry-run`

From `packages/flutter_ready`, after committing:

```
Publishing flutter_ready 0.1.1 to https://pub.dev:
├── CHANGELOG.md (<1 KB)
├── LICENSE (1 KB)
├── README.md (2 KB)
├── analysis_options.yaml (<1 KB)
├── bin/flutter_ready.dart (<1 KB)
├── example/README.md (1 KB)
├── lib/... (unchanged file list plus the reformatted files above)
├── pubspec.yaml (<1 KB)
└── test/...
Total compressed archive size: 36 KB.
Validating package...
The server may enforce additional checks.

Package has 0 warnings.
```

File list includes `example/README.md`, as required.

## `pana` (target 160/160)

Installed cleanly (`dart pub global activate pana`, already at 0.23.19).

Before the format fix (after the example + doc-comment fix only):
**150/160** — Provide documentation now 20/20 (example found), but Pass
static analysis still 40/50 (formatter-only, per above).

After `dart format .` on the 9 flagged `lib/` files:

```
## ✓ Follow Dart file conventions (30 / 30)
## ✓ Provide documentation (20 / 20)
### [*] 10/10 points: Package has an example
## ✓ Platform support (20 / 20)
## ✓ Pass static analysis (50 / 50)
## ✓ Support up-to-date dependencies (40 / 40)

Points: 160/160.
```

**160/160**, as targeted.

## Files changed

| File | Change |
|---|---|
| `packages/flutter_ready/example/README.md` | New — install, usage, real output (both outcomes), exit codes, Action snippet |
| `packages/flutter_ready/lib/src/replacements.dart` | Doc comment rewritten as a fenced json block; reformatted |
| `packages/flutter_ready/pubspec.yaml` | `version: 0.1.0` → `0.1.1` |
| `packages/flutter_ready/CHANGELOG.md` | Added `## 0.1.1` entry |
| `packages/flutter_ready/lib/{readiness_check.dart, src/check_command.dart, src/check_report.dart, src/live_check.dart, src/pubspec_lock.dart, src/readiness/live_grade.dart, src/readiness/pub_dev_client.dart, src/readiness/snapshot_model.dart}` | `dart format` only — no behaviour change; needed for pana's static-analysis score |

## Known issues or limitations

- The formatter drift affects 9 more files under `test/` too, but pana's
  static-analysis score doesn't check `test/`, so those were left as-is
  to keep the diff scoped to what the score needed. A future `dart format
  .` on the whole package will still report them as unformatted; that's
  pre-existing and outside this card.
- Per the architect gate: pushed to this clone's local `origin`
  (`~/flutter-ready`), not to github.com. The architect moves it from
  there and publishes 0.1.1 with the owner's go-ahead.

## Suggested commit message

Already used verbatim, as two commits on `feature/pub-score`:

```
Add example page and fix pub.dev doc-comment info; bump to 0.1.1

pub.dev scored 0.1.0 at 140/160: no example found (0/10), and one
analysis info about a doc comment's <package> placeholder leaking as
raw HTML because its inline-code span spanned two lines. Add
example/README.md (install, check usage, real output for both the
blocked and clean fixture apps, exit codes, GitHub Action snippet) and
rewrite the replacements.dart doc comment with a fenced json block.

Co-Authored-By: 10xs.ai
```

```
dart format lib/ to close the remaining pana static-analysis gap

pana's static-analysis score also runs `dart format --set-exit-if-changed`;
these 9 lib files predate the SDK's newer formatter style and were still
losing 10 points after the doc-comment fix. No behaviour change.

Co-Authored-By: 10xs.ai
```
