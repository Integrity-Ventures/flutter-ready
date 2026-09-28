# flutter_ready

Which of your Flutter plugins will block your next release?

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
suggested replacement, and exits with code `1` if anything blocks. Options:

- `--lockfile <path>`: path to `pubspec.lock`, if not in the current directory.
- `--data <path|url>`: an alternate readiness data source, instead of the
  published `latest.json`.
- `--offline`: never check an unlisted plugin live against pub.dev; it's
  reported as "not checked" instead.

See the live board at https://ready.hireflutter.dev.
