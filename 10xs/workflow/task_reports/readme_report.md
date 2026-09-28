# Completion Report: Modern README

Instruction: `10xs/workflow/instructions/20260928_23_readme.md@eb77fdb03be3e3f0cdf6d05aff1b4c302c83b14a`.
No new instruction file was written — the linked instruction already settles
this card's scope, per `00_ARCHITECT_GATE.md`'s "check this folder first"
rule.

Branch: `feature/readme`, pushed to this clone's local `origin` per
`00_ARCHITECT_GATE.md`. Commit: `eb77fdb03be3e3f0cdf6d05aff1b4c302c83b14a`.

Ran after the "Publish prep: one package" card, whose merge is already on
`develop` (confirmed: `packages/` has only `flutter_ready` and
`snapshot_job`, no separate `readiness_check`).

## Work completed

Docs only: `README.md`, `packages/flutter_ready/README.md`, and one new
image, `docs/images/board.png`. No code changes.

### `README.md`

Rewritten in the order the instruction specifies:

1. Centred top block: name, one-line pitch, and three badges (CI —
   `.github/workflows/ci.yml`'s own badge URL; MIT licence linking to
   `LICENSE`; a live-board badge linking to
   https://ready.hireflutter.dev). A pub.dev badge isn't added yet
   (`flutter_ready` isn't live on pub.dev) — left as an HTML comment marking
   where it goes, per the instruction.
2. A screenshot, `docs/images/board.png`, captured live (see below).
3. "Why this exists": the CocoaPods read-only date and the Play API 36 /
   16 KB alignment requirement, in plain words.
4. Features: board, CLI, GitHub Action, nightly refresh — short bullets.
5. Quick start: install + `flutter_ready check`, plus a **real** output
   block (below).
6. GitHub Action: a copy-paste snippet using `Integrity-Ventures/flutter-ready@main`
   with `action.yml`'s `lockfile` input.
7. Statuses table: Blocked / Unclear / Ready / Not affected / Not checked,
   copied verbatim from `site/lib/constants/status_colors.dart`'s
   `labelForCategory` (the single source both the board and this table now
   agree with).
8. How it works + a Mermaid flowchart (pub.dev search → nightly job →
   `data/latest.json` → board and CLI).
9. Repo layout tree.
10. Contributing: the three-command dev loop, issues/PRs welcome.
11. "Built with AI, managed by 10xs": kept the existing honest paragraph,
    tightened, with links to `BRIEF.md`/`SPEC.md`/`STATUS.md`.
12. Credits and licence line, exactly as specified.

Fixed the stale "(soon ready.hireflutter.dev)" line: confirmed the domain
is live now (`curl -o /dev/null -w '%{http_code}' https://ready.hireflutter.dev/`
→ `200`, resolving to `13.227.249.120`), so the README's live-board badge
and prose now point at `ready.hireflutter.dev` as the current, live URL
rather than "soon".

### `packages/flutter_ready/README.md`

Shortened to what pub.dev shows: pitch, install, usage with the same real
sample output, the same statuses table, a "More" section linking to the
live board and the GitHub repo, and the credits line. Every link is an
absolute URL (`https://...`); the one reference to the repo's fixtures
directory uses the absolute GitHub tree URL
(`https://github.com/Integrity-Ventures/flutter-ready/tree/develop/fixtures/sample_app`)
rather than a relative path, since pub.dev can't resolve relative links
outside the package.

### The screenshot

Captured with Playwright (1.63.0, Chromium) against the **live** board at
`https://ready.hireflutter.dev/` (already showing this repo's latest
`develop`, commit `7b4b390`, including the just-merged header/footer
redesign): viewport 1280×900, clipped to `(0, 0, 1280, 400)` — the top bar,
hero, and the four count tiles (83 Blocked, 8 Unclear, 45 Ready, 9 Not
affected), matching the instruction's "cropped to the top of `/`". Saved to
`docs/images/board.png` (33 KB). Alt text describes the four categories.

## Real command output (quoted, not invented)

All run at commit `eb77fdb03be3e3f0cdf6d05aff1b4c302c83b14a`.

Installed the way a stranger would, then ran against the checked-in
fixture app:

```
$ dart pub global activate --source path packages/flutter_ready
...
Activated flutter_ready 0.1.0 at path ".../packages/flutter_ready".

$ flutter_ready check --data fixtures/sample_app/data/latest.json --lockfile fixtures/sample_app/pubspec.lock --offline
Flutter Ready check — 1 hosted package(s) in pubspec.lock.

CocoaPods registry goes read-only (2026-12-02):
  BLOCKER: fixture_blocked_plugin 1.0.0: No Package.swift in the fixture_blocked_plugin archive. — from Flutter Ready data (2026-09-27)
    Suggested replacement: fixture_green_plugin — fixture-only suggestion, for golden tests
$ echo $?
1
```

This exact block (invocation + output) is what both READMEs quote.

## Checks

```
$ cd packages/flutter_ready && dart analyze --fatal-infos
Analyzing flutter_ready...
No issues found!

$ dart test
00:01 +96: All tests passed!
```

`dart analyze --fatal-infos` and `dart test` also re-run clean in
`packages/snapshot_job` (10 tests) and `site` (36 tests) — both untouched by
this card.

```
$ cd packages/flutter_ready && dart pub publish --dry-run
...
Total compressed archive size: 48 KB.
Validating package...
The server may enforce additional checks.

Package has 0 warnings.
```

(First run, before committing, warned only about uncommitted git state —
"1 checked-in file is modified in git" — a git-cleanliness note, not a
package-content problem; it cleared once the change was committed. No
relative link outside `packages/flutter_ready/` was added, so the
mutation the instruction describes — an out-of-package relative link
tripping the dry run — does not apply here.) **Never ran `dart pub publish`
for real.**

## Mermaid diagram

Rendered locally with `@mermaid-js/mermaid-cli` (`mmdc`, Puppeteer/Chromium,
`--no-sandbox`) directly from the fenced block in `README.md`, to both SVG
and a white-background PNG, confirming it parses and lays out as: `pub.dev
search → Nightly job → data/latest.json → {Public board, flutter_ready
CLI}`. (`mermaid.live` wasn't reachable from this sandbox the same way the
live board was; the local CLI render uses the same Mermaid engine GitHub's
web renderer uses, and is the check available here. The architect can
additionally confirm on the pushed branch's GitHub view once it's on
`github.com`.)

## Design notes

- **Live numbers, not stale ones.** `STATUS.md` (dated 2026-09-27) still
  says "146 ... 81 blocked"; the live board — after the gzip-padding and
  skip-empty-platform fixes that landed since — now shows 145/83/8/45/9.
  The README doesn't hardcode any of these numbers in prose (only the
  screenshot carries them), so it can't go stale the way a typed-out count
  would.
- **Statuses table wording.** Pulled directly from
  `site/lib/constants/status_colors.dart`'s `labelForCategory`, not
  retyped from memory, so it can't drift from the board's own words.
- **GitHub Action snippet.** `action.yml` only declares `lockfile` and
  `data` inputs (both optional); the snippet shows `lockfile` since that's
  the one most users will want to set, with a comment noting the default.

## Known issues / limitations

- No `pana` run was included — the instruction lists it as optional "if it
  installs cleanly," and the publish-prep card's report already covers the
  pub-points question; adding it here would be scope creep for a docs-only
  card.
- `docs/images/board.png` is a point-in-time screenshot; it will drift from
  the live counts as the nightly job runs. That's expected of any README
  screenshot and not something this card can fix.

## Suggested commit message

```
Descriptive, modern READMEs for the repo and the pub.dev package

Owner request 2026-09-28: "I want the README in the repo to be
descriptive and beautiful similar to modern opensource repos". Docs
only, no code changes.

- README.md: centred badges (CI, MIT, live board), a live board
  screenshot (docs/images/board.png, captured from
  ready.hireflutter.dev at 1280px), why the two deadlines matter,
  features, a quick start with real CLI output from
  fixtures/sample_app, a GitHub Action snippet, a statuses table
  matching the board's own words, a Mermaid pipeline diagram, a repo
  layout tree, contributing, the existing "built with AI" section
  tightened, and credits. Replaced the stale "soon
  ready.hireflutter.dev" line — the domain is live (curled 200).
- packages/flutter_ready/README.md: a shorter, pub.dev-facing version
  with the same real sample output and statuses table; only absolute
  GitHub URLs, since pub.dev can't resolve relative links outside the
  package.

Every command and number was run at this commit; see the completion
report for full output.

Co-Authored-By: 10xs.ai
```
