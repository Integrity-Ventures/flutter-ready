# Architect notes for cards e2-s1 … e6-s2 (architect, 2026-09-27)

Read `00_ARCHITECT_GATE.md` first. Find your card id below and follow its
section when you write your instruction file. These notes settle layout and
contract questions so the cards fit together. Anything here that SPEC leaves
open is marked **architect decision** and can be changed by the owner.

## Shared layout (architect decision)

| Path | What |
|---|---|
| `packages/readiness_check/` | Shared library (e1). Pure logic and pub.dev client, no file IO. |
| `packages/snapshot_job/` | Nightly job: a Dart CLI `bin/snapshot.dart` that depends on readiness_check by path. |
| `packages/flutter_ready/` | The CLI published as `flutter_ready` (e4). Depends on readiness_check by path for now. Publishing is held (e4-s3). |
| `site/` | The Jaspr static board (e3). |
| `data/deadlines.json` | Deadlines as data (SPEC open decision 6; architect decision). |
| `data/snapshots/<YYYY-MM-DD>.json` | One snapshot per run (UTC date). |
| `data/latest.json` | Copy of the newest snapshot, which the CLI and board read. |
| `data/replacements.json` | Hand-kept replacement suggestions (e4-s2). |

## Snapshot contract, schemaVersion 1 (architect decision)

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-09-27T02:00:00Z",
  "topN": 100,
  "plugins": [{
    "name": "url_launcher", "version": "6.3.1", "published": "2026-…Z",
    "downloadCount30Days": 0, "likeCount": 0,
    "swiftpm": {"tag": true, "archive": true, "agrees": true,
                "checkedPackage": "url_launcher_ios"},
    "alignment": {"checkedPackage": "url_launcher_android",
                  "soFiles": [{"path": "…", "aligned": true, "minAlign": 16384}]},
    "android": {"checkedPackage": "…", "compileSdk": 35, "agp": "8.5.0", "ndk": null},
    "errors": []
  }]
}
```

- Keep fields that are absent as `null`, never omit them. A per-plugin
  failure goes into `errors` (a string list) and never aborts the run.

## e2-s1: Snapshot assembly

- **Federated plugins (review finding on e1-s2).** For app-facing packages
  like `url_launcher`, `Package.swift`, `.so` files and Gradle files live in
  the endorsed platform packages. Read
  `latest.pubspec.flutter.plugin.platforms.<ios|macos|android>.default_package`
  from `GET /api/packages/<name>`. When it's set, run the archive checks on
  that package's latest archive, and record it as `checkedPackage`.
  Otherwise check the plugin's own archive. The `is:swiftpm-plugin` tag
  stays the app-facing package's tag.
- `bin/snapshot.dart --top N --out data/snapshots/` writes the dated file
  and `data/latest.json`. Limit concurrency to 4 and send a descriptive
  User-Agent.
- Tests: offline with MockClient, including one federated case. Also do
  one live run with `--top 100` on the fleetbox and commit its output
  (`data/snapshots/<date>.json` + `data/latest.json`), so the board and CLI
  have real data. Put the run's duration and plugin count in your report.

## e2-s2: Scheduling and commit

- `.github/workflows/nightly-snapshot.yml`: a daily cron (02:00 UTC) plus
  `workflow_dispatch`. Set up Dart, run the job, and commit `data/` with a
  bot identity and message trailer `Co-Authored-By: 10xs.ai`. Use
  `permissions: contents: write`, commit only when something changed, and
  target the default branch.
- Also add `.github/workflows/ci.yml`: `dart analyze --fatal-infos` and
  `dart test` for every package under `packages/`, on push and PR, keeping
  the test output as an artifact (SPEC §5).
- The workflow must not need any secret beyond the built-in GITHUB_TOKEN.

## e3-s1: Board rendering

- Jaspr static mode in `site/`. Read `data/latest.json`, all of
  `data/snapshots/`, and `data/deadlines.json` at build time. Build one index
  page plus one page per plugin at `/p/<name>/`.
- Colours (architect decision):
  - **SwiftPM:** green when tag and archive both say ready; amber when
    they disagree; red when both say not ready.
  - **16 KB:** green when every .so is aligned or the archive has no .so
    (label it "no native libs in archive"; SPEC §4); red when any .so is
    misaligned, showing its path and minAlign.
  - **Android:** facts only, no colour (SPEC open decision 3).
  - A plugin with `errors` shows grey "not checked", never green.
- Trend: the share of plugins with SwiftPM green, per snapshot date.
- Screenshot evidence is required (QA doctrine). Build and serve locally on
  the fleetbox on a port other than 3000/3001/4000, and screenshot with
  Playwright.

## e3-s2: Red-row call to action

- On red rows and red plugin pages: "Blocked by this plugin? A HireFlutter
  developer can migrate or fork it." Link it to `https://hireflutter.dev`.
  Screenshot evidence.

## e3-s3: Deployment. HELD, do not start (owner decision: Amplify spend and DNS).

## e4-s1: check command

- `packages/flutter_ready/bin/flutter_ready.dart check [--data <path|url>]`.
  The default data source is
  `https://raw.githubusercontent.com/Integrity-Ventures/flutter-ready/main/data/latest.json`
  (architect decision; the owner may switch it to ready.hireflutter.dev
  later).
- Read `pubspec.lock`. For each hosted package that's in the data at the
  same version, report per-deadline blockers with evidence. A package
  that's missing, or at a different version, is "not checked", never
  green (SPEC §3.3). Exit 1 on any blocker and 0 otherwise. Android is
  facts only.
- Use the same grading functions as the board: put them in
  readiness_check, so the board and CLI can't disagree (SPEC §2).

## e4-s2: Replacement suggestions

- `data/replacements.json` is hand-kept: `{"<package>": [{"replacement":
  "…", "note": "…", "source": "…"}]}`. Ship it empty (`{}`), or with at
  most 2 entries marked `"seed": true` that you've verified by hand. Never
  generate suggestions. The CLI prints the suggestion under each blocker.

## e4-s3: Publish. HELD, do not start (owner decision: irreversible pub.dev publisher).

## e5-s1: Action wrapper

- A composite action in `action.yml` at the repo root: set up Dart, run
  `dart pub global activate --source path packages/flutter_ready` (until
  published), then `flutter_ready check`. Fail on exit 1.
- Verify it with a workflow in this repo that runs the action against a
  fixture app `pubspec.lock` holding a known blocker. It must fail.
  Record that failing run in the report. No external sample repo tonight.

## e6-s1: Fixtures (if not already merged)

- `packages/readiness_check/test/fixtures/`, as the card says. Include one
  federated plugin set (app-facing plus `_ios` and `_android`).

## e6-s2: Golden CLI tests

- `packages/flutter_ready/test/goldens/`: golden text for the `check`
  report, covering blockers, not checked, a clean run and a suggestion
  line. Have CI keep the test output (e2-s2's ci.yml).
