# flutter_ready

**Which of your Flutter plugins will block your next release?**

`flutter_ready` reads your app's `pubspec.lock` and reports which of your
plugins aren't ready for this season's platform deadlines:

- **Swift Package Manager**, before CocoaPods goes read-only on
  2 December 2026.
- **16 KB-aligned native libraries**, for Android API 36 on Google Play.

It checks each locked plugin against the
[Flutter Ready](https://ready.hireflutter.dev) data, and falls back to a
live check against pub.dev for any plugin the data doesn't cover yet.

## Install

```sh
dart pub global activate flutter_ready
```

## Use

Run it from your app's root, next to `pubspec.lock`:

```sh
flutter_ready check
```

It prints a report of any blocking plugin, with evidence and (where known) a
suggested replacement, and exits with code `1` if anything blocks. Real
output, run against a sample app pinned to a plugin that's always graded red
(see
[`fixtures/sample_app`](https://github.com/Integrity-Ventures/flutter-ready/tree/develop/fixtures/sample_app)
in the repo):

```
$ flutter_ready check --data fixtures/sample_app/data/latest.json --lockfile fixtures/sample_app/pubspec.lock --offline
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive. — from Flutter Ready data (2026-09-27)
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
```

Options:

- `--lockfile <path>`: path to `pubspec.lock`, if not in the current directory.
- `--data <path|url>`: an alternate readiness data source, instead of the
  published `latest.json`.
- `--offline`: never check an unlisted plugin live against pub.dev; it's
  reported as "not checked" instead.

## What the statuses mean

| Status | Meaning |
|---|---|
| **Blocked** | Fails a deadline check today. |
| **Unclear** | Signals disagree — check the plugin's page on the board for the evidence. |
| **Ready** | Passes the check. |
| **Not affected** | The deadline doesn't apply to this plugin. |
| **Not checked** | Couldn't be verified — never shown as green. |

## More

- Live board: [ready.hireflutter.dev](https://ready.hireflutter.dev)
- Source, issues and the GitHub Action:
  [github.com/Integrity-Ventures/flutter-ready](https://github.com/Integrity-Ventures/flutter-ready)

Built by Integrity Ventures Private Limited ([ivp.life](https://ivp.life)) ·
hosted by HireFlutter ([hireflutter.dev](https://hireflutter.dev)) · MIT
licensed.
