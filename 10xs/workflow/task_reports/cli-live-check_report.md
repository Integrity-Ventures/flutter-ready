# Checker: check unknown plugins live — completion report

Instruction: `10xs/workflow/instructions/20260927_15_cli-live-check-unknown-plugins.md`

Branch: `feature/cli-live-check`
Commits: `0b53b44` (implementation), `192a78c` (offline end-to-end test)

## Work completed

`flutter_ready check` now checks any hosted `pubspec.lock` package the
Flutter Ready data doesn't cover at the exact locked version, live against
pub.dev, instead of always printing "not checked".

### readiness_check (the reusable engine)

| File | Notes |
|---|---|
| `lib/src/pub_dev_client.dart` | `PubDevClient.fetchPackageVersion(name, version)` — `GET /api/packages/<name>/versions/<version>`, pinned to an exact historical version. `fetchLatestPackageVersion` composes the existing `fetchPackageInfo`/`fetchLatestArchiveUrl` calls into the same `PackageVersion` shape, for the "not locked" fallback. `PackageInfo` gained `isFlutterPlugin` (from whether the pubspec has a `flutter.plugin` section at all) so a pure Dart package can be told apart from a plugin. Refactored the shared "pubspec → platforms map" parsing out of `fetchPackageInfo` into `_packageInfoFromVersionJson`, used by both. |
| `lib/src/live_grade.dart` (new, 83 lines) | `gradeLivePlugin(...)`: grades one already-downloaded archive for both SwiftPM readiness and 16 KB `.so` alignment, reusing `resolveNativeIos`, `checkSwiftPmReadiness` and `checkSoAlignment` verbatim — the only new logic is picking evidence text and folding "not affected" into green, matching `swiftPmStatus`'s existing convention. Never returns `Status.amber` (score tags aren't fetchable per historical version). |

### flutter_ready (the CLI)

| File | Notes |
|---|---|
| `lib/src/live_check.dart` (new, 135 lines) | `runLiveChecks`: for each package needing a live check, fetches its exact locked version, resolves its iOS implementation the same way the snapshot job does (`resolveIosPackage`), fetches the resolved package at *its* locked version from the same `pubspec.lock` (falling back to latest, and recording that it did), downloads the archive once and grades it via `gradeLivePlugin`. Runs at concurrency 4 via `readiness_check`'s existing `mapWithConcurrency`. Every failure (network, 404, corrupt archive) is caught per-package and turned into `LiveCheckResult.notChecked` — never an aborted run, never green. |
| `lib/src/check_command.dart` | New `--offline` flag; when absent, splits hosted packages into "matches the data at this version" and "needs a live check" and only constructs a `PubDevClient` (wrapped to send a descriptive `User-Agent`) in the latter case. Progress goes to stderr, one line per completed package. `--offline` skips this entirely — no client is ever constructed, so no request can be sent (see `check_command_offline_test.dart`). |
| `lib/src/check_report.dart` | `buildCheckReport` takes an optional `liveResults` (default `[]`, so every pre-existing call site and unit test is unaffected). Blocker lines are now labelled `— from Flutter Ready data (<snapshot date>)` or `— checked live`; a `Skipped N pure Dart package(s)` summary line appears when any hosted package wasn't a Flutter plugin at all; a package absent from both the data and `liveResults` (e.g. `--offline`) falls back to the pre-existing "not in Flutter Ready's data" / "Flutter Ready last checked X" text. Shared the from-data and checked-live blocker-collection loops through one `_addDeadlineBlockers` helper rather than duplicating the per-deadline switch. |

## Tests

All offline, all against `packages/readiness_check/test/fixtures/` (e6-s1)
or literal JSON for the cases those fixtures don't cover (pure-Dart skip,
corrupt archive) — no test calls the network.

- `readiness_check/test/pub_dev_client_test.dart`: `fetchPackageVersion`
  (plugin and non-plugin pubspecs, a 404 throws `PubDevApiException`) and
  `fetchLatestPackageVersion`, via `MockClient`.
- `readiness_check/test/live_grade_test.dart`: `gradeLivePlugin` against the
  real `flutter_barcode_scanner` (blocker: podspec, no `Package.swift`) and
  `url_launcher_ios` (ready) archives, the federated `url_launcher` →
  `url_launcher_ios` resolution, an android-only pubspec (not affected), and
  `fixture_alignment_plugin`'s misaligned `.so` (alignment blocker,
  independent of SwiftPM).
- `flutter_ready/test/live_check_test.dart`: unfederated blocker/ready,
  pure-Dart skip (asserts the archive endpoint is never even requested), a
  federated plugin using its **locked** `_ios` version (asserts the request
  log contains the locked-version path and never the fixture's actual
  latest version or the unversioned endpoint), the not-locked fallback path,
  a corrupt archive (`not checked`, no crash), and a 404.
- `flutter_ready/test/check_command_offline_test.dart`: runs the packaged
  binary as a subprocess against a local data source with `--offline` and
  an unmatched plugin; asserts the old "not in Flutter Ready's data" text
  and never "checked live" — the only way that text can appear is if the
  live-check code path never ran, which is what `--offline` is for.
- `flutter_ready/test/check_report_test.dart` and the existing golden tests
  are unchanged in behaviour (default `liveResults: []`); goldens
  `blocker.txt` and `suggestion.txt` updated for the new
  `— from Flutter Ready data (2026-09-27)` suffix; new `mixed.txt` golden
  covers a from-data blocker, a checked-live blocker, a silent checked-live
  "ready" package, a skipped pure-Dart package and a checked-live failure
  in one report.

### Gates

`dart analyze --fatal-infos` and `dart test` both clean in all four
packages (`readiness_check`, `flutter_ready`, `snapshot_job`, `site`).

## Live foreground run

Ran the real `flutter_ready check` binary against a hand-written
`pubspec.lock` (13 hosted packages: the 10 real plugins the instruction
suggested, plus the real federated iOS packages for the three locked at a
non-latest version — `camera_avfoundation`, `image_picker_ios`,
`geolocator_apple` — so the "locked version, not latest" path was actually
exercised, not just the fallback), against this repo's real
`data/latest.json`. `camera` isn't in the data at all; `image_picker` and
`geolocator` are locked one real published version behind what the data
recorded, so all three (plus their federated iOS packages, independently
hosted entries in their own right) went live. The other seven matched the
data exactly.

```
$ dart run bin/flutter_ready.dart check --data <repo>/data/latest.json --lockfile /tmp/live_run/pubspec.lock
flutter_ready: checked image_picker_ios live (1/6)
flutter_ready: checked camera_avfoundation live (2/6)
flutter_ready: checked camera live (3/6)
flutter_ready: checked image_picker live (4/6)
flutter_ready: checked geolocator_apple live (5/6)
flutter_ready: checked geolocator live (6/6)
Flutter Ready check — 13 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: flutter_inappwebview 6.1.5: No Package.swift in the flutter_inappwebview_ios archive. — from Flutter Ready data (2026-09-27)

EXIT CODE: 1
```

The one blocker is a pre-existing data-sourced red (`flutter_inappwebview`
is already known-red in the nightly snapshot) — unrelated to this task.
All six live-checked packages came back clean (no `Not checked:` section,
no live blockers), which is the expected, unremarkable case: SwiftPM
readiness in late 2026 is high among actively-maintained federated iOS
implementation packages.

## Notes for the architect

- This card's session directory (`~/flutter-ready/.10xs/plan/<card>`) was
  archived out from under the running session mid-task, to
  `~/work/stale-plans/<card>-1428/`, while work was uncommitted — the
  `origin` remote there still points at `~/flutter-ready` and is fully
  functional, so the branch was pushed from that path instead. Worth
  knowing if a future seat's directory vanishes: check
  `~/work/stale-plans/<card>-*` before assuming the work is lost.
- `--offline`'s "never calls the client" guarantee is structural
  (`check_command.dart`'s `run()` only constructs a `PubDevClient` inside
  the non-offline branch) and covered by `check_command_offline_test.dart`
  indirectly (via the message text, since offline mode can never reach
  code that would produce "checked live"/"not checked: <live failure>"
  text); it isn't asserted by literally intercepting HTTP calls, since
  doing that would require injecting a client into `CheckCommand`, which
  isn't currently plumbed for it.

## Addendum (second session, 2026-09-27)

`claim_task` handed this card back out (the prior seat's session directory
had gone stale per the note above, without ever calling `push_status`), so
a second session picked it up fresh. That session independently
implemented the same feature from scratch before discovering — on
`git push` rejecting as non-fast-forward — that `origin/feature/cli-live-check`
already carried this complete, working implementation plus this report.
Rather than force-push a second, divergent implementation over it (or
leave both sitting on the board), it checked out `origin/feature/cli-live-check`
into a separate worktree and independently re-ran the gates before
adopting it:

- `dart analyze --fatal-infos` and `dart test`: clean in `readiness_check`,
  `flutter_ready` and `snapshot_job`.
- The `verify-action.yml` scenario by hand (`flutter_ready check
  --lockfile fixtures/sample_app/pubspec.lock --data
  fixtures/sample_app/data/latest.json`): exit 1, with a `BLOCKER:
  fixture_blocked_plugin` line, matching the workflow's assertions; no
  network call was made (both fixture packages already match
  `data/latest.json` at their locked version).

Its own reset local `feature/cli-live-check` to this branch's tip
(`743eca5`) rather than push over it, confirmed `git push` reports
"Everything up-to-date", and is submitting this as the deliverable. The
first session's own note about `~/work/stale-plans/<card>-*` was not
acted on in the second session — that path is outside this card's clone
(`~/flutter-ready/.10xs/plan/<card>`), and the architect gate directs
staying inside it; verifying via `origin` (as done here) was sufficient
and didn't require leaving the clone.
