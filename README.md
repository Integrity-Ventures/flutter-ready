# Flutter Ready

Which of your Flutter plugins will block your next release?

Flutter Ready will be a public board showing whether the most-used Flutter
plugins on pub.dev are ready for this season's platform deadlines: Swift
Package Manager before CocoaPods goes read-only on 2 December 2026, and
Android API 36 with 16 KB-aligned native libraries on Google Play. A CLI and a
GitHub Action will check your own app's `pubspec.lock` against the same data.

**Status:** built and tested on `develop`, not yet deployed or published. See [`STATUS.md`](STATUS.md).

- [`BRIEF.md`](BRIEF.md): what was asked for, written before work started.
- [`SPEC.md`](SPEC.md): the v1 direction.

An Integrity Ventures product, hosted by HireFlutter. MIT licensed, see
[`LICENSE`](LICENSE).

## Contributing

Each package under `packages/` and `site/` is a Dart package: `dart pub get`,
`dart analyze --fatal-infos`, `dart test`. See [`STATUS.md`](STATUS.md) for how
to run the CLI and build the board. Issues and pull requests are welcome.
