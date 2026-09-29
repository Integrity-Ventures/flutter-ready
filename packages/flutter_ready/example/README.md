# Example: checking an app's plugins

## Install

```sh
dart pub global activate flutter_ready
```

## Run it in an app

From the app's root, next to its `pubspec.lock`:

```sh
flutter_ready check
```

This downloads the latest [Flutter Ready](https://ready.hireflutter.dev)
data and checks every hosted plugin locked in `pubspec.lock` against it,
falling back to a live pub.dev check for any plugin the data doesn't cover.

Two options that are useful in CI or when testing against a fixed data
snapshot:

- `--lockfile <path>`: path to `pubspec.lock`, if not in the current
  directory.
- `--offline`: never check an unlisted plugin live against pub.dev; it's
  reported as "not checked" instead of making a network call.

## Real output

Run against the repo's own test fixture app, pinned to a plugin that's
always graded red, and to a fixed data snapshot instead of the live one:

```sh
$ flutter_ready check --data fixtures/sample_app/data/latest.json --lockfile fixtures/sample_app/pubspec.lock --offline
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive. — from Flutter Ready data (2026-09-27)
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
$ echo $?
1
```

Against an app with no blocking plugins, it prints a one-line summary and
exits `0`:

```sh
$ flutter_ready check --data fixtures/sample_app/data/latest.json --lockfile fixtures/sample_app/pubspec_green.lock --offline
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

No blockers found.
$ echo $?
0
```

Exit code `0` means nothing blocks; `1` means at least one plugin does.

## In a GitHub Action

The repo ships a composite action that runs the same check and fails the
job on a blocker:

```yaml
- uses: Integrity-Ventures/flutter-ready@main
  with:
    lockfile: pubspec.lock
```
