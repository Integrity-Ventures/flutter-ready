# Microtask Instruction: CLI checks unknown plugins live (OPEN)

Status: **OPEN.** Written by the architect on 2026-09-27; the owner approved
it. Executed by the card "Checker: check unknown plugins live".

## Why

`flutter_ready check` only knows the ~146 plugins in `data/latest.json`.
Every other plugin in an app prints "not checked", so the tool can't
answer for a real app. The deep check already exists in
`packages/readiness_check`; the CLI should run it on the spot for any
plugin the data doesn't cover.

## Behaviour

For each hosted package in the app's `pubspec.lock`:

1. **In the data at the same version:** use the data, as today. Label it
   "from Flutter Ready data (<snapshot date>)".
2. **Otherwise:** check it live, at the **exact locked version**, not
   latest:
   - `GET https://pub.dev/api/packages/<name>/versions/<version>` gives its
     pubspec and archive_url.
   - **Not a Flutter plugin** (no `flutter.plugin` in its pubspec): skip it
     silently. Pure Dart packages can't block a native build. Mention the
     skipped count in one summary line.
   - **Plugin:** resolve the iOS implementation with the same rules as the
     snapshot job. For an `ios`/`macos` `default_package`, use **that
     package's version from the same pubspec.lock** (e.g. url_launcher_ios
     6.3.1), falling back to its latest only if it isn't locked, and say so.
     Download the archive and run the existing checks: SwiftPM
     (Package.swift present / native iOS code / not an iOS plugin) and 16 KB
     alignment of any `.so`.
   - Score tags can't be fetched per version, so grade live checks on the
     archive alone. Package.swift present means ready; native iOS code
     without it means **blocker**; no native iOS code or no iOS platform
     means not affected. Label it "checked live".
   - Any failure (network, 404, corrupt archive) makes that package "not
     checked: <reason>", never green, and never aborts the run.
3. Blockers from live checks count toward exit code 1, exactly like data
   blockers.
4. `--offline`: no network; unknown plugins print "not checked", as today.
   Concurrency 4; a descriptive User-Agent; a short progress line on stderr.

Reuse readiness_check's functions (PubDevClient, archive listing, iOS
resolution, grading). Add only what's missing: a version-specific fetch and
a function that grades one package from its pubspec and archive. Keep files
under 200 lines.

## Tests (offline, never the network)

- Using the e6-s1 fixtures and MockClient: an unknown plugin with no
  Package.swift is a live blocker (exit 1); one with Package.swift is ready;
  a pure Dart package is skipped; a federated plugin uses the locked
  `_ios` version; a corrupt archive is "not checked", with no crash;
  `--offline` never calls the client.
- Update the goldens for the new labels and add a golden for a mixed report
  (data plus live plus skipped). The Verify Action workflow must stay green;
  its fixture plugins are all in fixture data, so no network is needed.

## Acceptance

- `dart analyze --fatal-infos` and `dart test` pass in all four packages.
- Run it live once on the fleetbox, in the FOREGROUND, against a real app
  lockfile. Build it by running `flutter create`-free: write a pubspec.lock
  by hand with ~10 real plugins, some in our data and some not (e.g.
  `flutter_inappwebview`, `device_info_plus`, `camera`, `webview_flutter`,
  `firebase_messaging`, `flutter_local_notifications`, `share_plus`,
  `image_picker`, `geolocator`, `permission_handler` at current versions).
  Paste the report into your completion report.
- Follow `00_ARCHITECT_GATE.md`: your own clone, foreground, lane branch
  `feature/cli-live-check`, and a report at
  `10xs/workflow/task_reports/cli-live-check_report.md`.
