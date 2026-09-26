# Microtask Instruction: e1-s1 — Plugin discovery and filtering

## Objective

Give the shared readiness-check library a way to produce the candidate plugin
list that every other check in epic e1 (SwiftPM, alignment, Android facts) and
the nightly job (e2) will run against: the top-N package names from pub.dev,
narrowed to actual Flutter plugins.

## Context

- Nothing is built yet (`STATUS.md`). This microtask starts the shared Dart
  library referenced throughout `SPEC.md` §3.1.1: "The job and the CLI share
  one readiness-check library, so the board and the CLI can't disagree."
- SPEC §3.1.1: call `GET https://pub.dev/api/package-name-completion-data`,
  which returns `{"packages": [...]}` ordered by overall ranking (pub.dev/help/api).
  Confirmed live 2026-09-26. Take the top N of that list, then keep only the
  ones whose `GET /api/packages/<name>/score` tags include `sdk:flutter` and at
  least one of `platform:ios` / `platform:android` — confirmed live 2026-09-26
  against `url_launcher` (tags include `sdk:flutter`, `platform:ios`,
  `platform:android`).
- N is an open decision (SPEC §7 item 1). Implement it as a parameter with a
  default of 100, per the board checklist item.
- Dependencies: none. This is the first microtask in the repo.

## Implementation Steps

1. Create a new Dart package at `packages/readiness_check/` (the shared
   library named in SPEC §3.1.1), with its own `pubspec.yaml` (SDK constraint,
   `http` dependency, `test`/`lints` dev dependencies).
2. `lib/src/pub_dev_client.dart` — a thin HTTP client wrapping the two pub.dev
   endpoints above, taking an injectable `http.Client` so tests never hit the
   network.
3. `lib/src/plugin_discovery.dart` — `discoverFlutterPlugins(client, topN:
   100)`: take the first `topN` names from the completion-data list, fetch
   each one's score tags, and keep the ones matching the SPEC §3.1.1 filter.
   Return a `PluginCandidate` (name + tags) per keeper, so downstream checks
   (e1-s2..s4) don't need to refetch tags already in hand.
4. `lib/readiness_check.dart` — public export file for the package.
5. `test/plugin_discovery_test.dart` — unit tests against a fake `http.Client`
   (canned JSON bodies, no network), covering: filters out non-Flutter
   packages, filters out Flutter packages with no ios/android platform tag,
   respects `topN`, and preserves order.

## File Scope

Implementation (4 files, within the 5-file limit):
- `packages/readiness_check/lib/readiness_check.dart`
- `packages/readiness_check/lib/src/pub_dev_client.dart`
- `packages/readiness_check/lib/src/plugin_discovery.dart`
- `packages/readiness_check/pubspec.yaml`

Test (exempt from the limit):
- `packages/readiness_check/test/plugin_discovery_test.dart`

## Acceptance Criteria

- `discoverFlutterPlugins` returns only packages tagged `sdk:flutter` plus at
  least one of `platform:ios` / `platform:android`.
- `topN` is a parameter, default 100, applied to the raw completion-data list
  before filtering (per SPEC §3.1.1: "Take the top N ... keep only ...").
- No implementation file exceeds 150 lines.
- `dart analyze` is clean and `dart test` passes with zero network calls.

## Testing Strategy

Unit tests only, using a fake `http.Client` returning fixture JSON bodies
captured from the live endpoints (see Context). No integration test against
the real pub.dev API in this microtask — that risk is covered later by e6-s1
(recorded fixtures) and e6-s2 (golden CLI tests).
