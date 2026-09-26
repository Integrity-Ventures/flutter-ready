# Flutter Ready: spec

**Status:** v1 direction, 2026-09-26. Nothing is built yet (see `STATUS.md`).
This is the direction 10xs builds from. It is **not** the brief: `BRIEF.md`
holds the owner's own words, is committed first and is never edited.

Source: Integrity Ventures' build slate v3 (2026-09-23, kept in a private
repo) §3 idea 1, §6.1 and §6.2. Facts marked
"checked 2026-09-26" were checked for this spec. Anything not settled is listed
under "Open decisions", not guessed.

## 1. What it is

A public board showing, for the most-used Flutter plugins on pub.dev, whether
each one is ready for this season's platform deadlines. It comes with a CLI and
a GitHub Action that check an app's own `pubspec.lock` against the same data
and fail CI before the store does.

The deadlines v1 covers:

| Deadline | Source |
|---|---|
| The CocoaPods registry goes read-only on 2 December 2026 | Flutter blog, 30 April 2026 |
| New apps and updates on Google Play must target API 36 from 31 August 2026, with extensions to 1 November 2026 | Play Console help |
| Native `.so` libraries must be 16 KB page-aligned | Play requirement, via slate §3 |

## 2. Who it's for, and where it lives

- **Users:** Flutter app teams who need to know which plugin will block their
  next release, and plugin authors, who get a public nudge.
- **Code:** an open-source repo in the Integrity Ventures GitHub org, under the
  MIT licence (owner, 2026-09-26). pub.dev also awards points for an
  OSI-approved licence.
- **Board:** hosted at `ready.hireflutter.dev`, in HireFlutter's brand, deployed
  from this repo. It doesn't wait for the hireflutter.dev revamp.
- **Hosting:** AWS Amplify static hosting (owner, 2026-09-26), like the
  owner's other sites. There is no backend: no server, database or login.
- **Stack:** Dart throughout (owner, 2026-09-26).
  - The CLI, the GitHub Action and the nightly job are Dart. The job and the
    CLI share one readiness-check library, so the board and the CLI can't
    disagree.
  - The board is a static site built with [Jaspr](https://jaspr.site/), a Dart
    web framework that renders real HTML and CSS. It is not Flutter Web, which
    draws on a canvas and is weak for search and first load. Each plugin gets
    its own page, so a search like "is <plugin> SwiftPM ready" can find it.
    Flutter's own sites (dart.dev, flutter.dev, docs.flutter.dev) moved to
    Jaspr in April 2026.
- **Package:** published on pub.dev under the `hireflutter.dev` publisher.
  Moving a package to a publisher can't be undone, so the publisher must exist
  before the first publish.
- **Call to action on each red plugin:** "Blocked by this plugin? A HireFlutter
  developer can migrate or fork it" (slate §6.1).

## 3. v1 scope

### 3.1 Nightly data job

1. **Pick the plugins.** Take the top N Flutter plugins from
   `GET https://pub.dev/api/package-name-completion-data`, which returns
   package names "ordered by overall ranking" (documented at pub.dev/help/api).
   The list mixes Dart packages and plugins, so keep only packages whose score
   tags include `sdk:flutter`, `is:plugin`, and at least one `platform:ios` or
   `platform:android` tag (added 2026-09-27, acting PM for the owner:
   pure-Dart packages such as provider and flutter_map carry the platform
   tags too; url_launcher and shared_preferences carry is:plugin). N is
   counted after this filter: take plugins from the ranked list, in order,
   until N are found.
2. **Record per plugin, for its latest version:**
   - **SwiftPM:** pub.dev's `GET /api/packages/<name>/score` already carries an
     `is:swiftpm-plugin` tag (checked 2026-09-26 on `url_launcher`,
     `firebase_core` and `flutter_webrtc`). The tag isn't in pub.dev's API
     docs, so also confirm it from the package archive: a
     `ios/<plugin>/Package.swift`, `macos/<plugin>/Package.swift` or
     `darwin/<plugin>/Package.swift` (Flutter's plugin-author guide). Record
     both, and flag any plugin where they disagree. Flutter's own tooling
     misreports this for some plugins (flutter/flutter#187330).
   - **16 KB alignment:** for every `.so` file inside the package archive, read
     the ELF program headers and check that each `LOAD` segment's alignment is
     at least 16 KB (0x4000).
   - **Android build settings** declared in the plugin's `android/build.gradle`
     or `build.gradle.kts`: `compileSdk`, the AGP version and the NDK version,
     when present. See open decision 3 on how these are graded.
   - Also recorded: the version, publish date, `downloadCount30Days` and
     `likeCount` from the score endpoint.
3. **Store it** as dated JSON snapshots committed to this repo, so the board
   can show trend over time. The job runs as a scheduled GitHub Actions
   workflow and commits each snapshot, and Amplify rebuilds the board on that
   commit.

### 3.2 Public board

- A static Jaspr site (§2): one row per plugin, red, amber or green for each deadline.
- Trend over time from the snapshots, for example the share of top plugins
  that ship SwiftPM.
- Each row links to the plugin's pub.dev page and shows the evidence behind its
  colour: the file found, or the misaligned library and its alignment.
- A red row carries the HireFlutter call to action (§2).

### 3.3 CLI

- Installed with `dart pub global activate flutter_ready`.
- `flutter_ready check`, run in an app repo, reads `pubspec.lock`, looks up
  each resolved plugin version in the published data, and prints a report:
  - blockers per deadline, with the evidence;
  - a suggested replacement package per blocker, where one is known (see open
    decision 4).
- It exits non-zero when a blocker is found, so CI fails.
- A plugin version that isn't in the published data (not in the top N, or
  newer than the last run) is reported as "not checked", never as green.

### 3.4 GitHub Action

A thin wrapper around the CLI that runs `flutter_ready check` and fails the job
on blockers.

## 4. Out of scope for v1

- Checking plugins outside the top N on the board. The CLI still reports them
  as "not checked".
- Native libraries that reach the app outside the package archive, for example
  from Maven or CocoaPods at build time. v1 only sees `.so` files shipped
  inside the pub.dev archive, and the board says so.
- Checking a built APK or AAB. The existing shell script and
  `flutter_spm_doctor` already do per-app local checks.
- Anything inside the hireflutter.dev codebase.

## 5. Tests

- Fixture packages for each readiness state: SwiftPM present, absent, and tag
  and archive disagreeing.
- pub.dev API responses recorded as fixtures, so tests never call the network.
- ELF alignment checks on sample `.so` files, aligned and misaligned.
- Golden tests of the CLI report output.
- The build record needs `tests` and `test_output` from a real run, so the
  test suite must run in CI and keep its output.

## 6. Done means

- The nightly job has run and the board is live at `ready.hireflutter.dev`,
  showing real, named plugins.
- `flutter_ready` is published on pub.dev under `hireflutter.dev`.
- The Action runs on a sample app repo and fails on a known blocker.
- All of this before 2 December 2026.
- A screenshot of the board is taken for the build record (`images.result`).

## 7. Open decisions (owner or build architect)

1. **N:** how many plugins the board covers. The Flutter blog's figure is for
   the top 100 iOS plugins, which suggests at least 100.
2. **Name:** `flutter_ready` was free on pub.dev on 2026-09-26 (the API
   returned 404). Check GitHub too before creating the repo.
3. **How to grade Android.** The API 36 rule applies to the app's
   `targetSdk`, not to a plugin's. What a plugin's `compileSdk`, AGP or NDK
   setting means for an app targeting API 36 needs to be settled from sources
   before those columns get a colour. Until then v1 can show them as facts,
   without red, amber or green.
4. **Replacement suggestions:** where they come from. The slate names them but
   gives no source. They could be curated by hand; they should never be
   generated.
5. **The `ready.hireflutter.dev` DNS record:** who adds it, pointing at the
   Amplify app. Hosting itself is decided: Amplify (§2).
6. **How deadlines are listed:** as data, so next season's Play and Apple
   deadlines can be added without code changes (slate §3 idea 1, risks).
