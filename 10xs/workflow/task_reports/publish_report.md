# Publish (e4-s3): report

Architect: ARCH-Flutter-Ready, 2026-09-28. Times IST.

- **Process:** discussed with the owner first, as they asked, and done last.
  The owner chose option (b), one self-contained package. The hireflutter.dev
  publisher already existed (registered 5 years ago); hireflutterdev@gmail.com
  is an admin (Admin and Activity log tabs visible).
- **Prep merged:** bdbe42e moved readiness_check into flutter_ready (snapshot_job
  and site depend on it by path; 138 tests; dry run 0 warnings). a1581c7 added
  `.pubignore`, which leaves `test/fixtures/` out of the upload. That folder
  holds copies of url_launcher (BSD-3, The Flutter Authors) and
  flutter_barcode_scanner (MIT, Amol Gangadhare) files; their notices are in
  `packages/flutter_ready/test/fixtures/THIRD_PARTY.md`. Upload size 35 KB.
- **pub.dev policy check:** https://pub.dev/policy and
  https://dart.dev/tools/pub/publishing say nothing about AI-written code.
  Removal grounds are name squatting, spam, malware, trademark and copyright.
- **Secrets check before publishing:** all 76 commits and the upload file list
  scanned for AWS, GitHub, Anthropic, OpenAI, Google and Slack keys, private
  keys, bearer tokens, JWTs and password assignments: none. The three real
  local tokens (the 10xs MCP bearer and connection token) appear nowhere in the
  history. Local-only files (HANDOFF.md, the fleetbox guide, CLAUDE.md,
  AGENTS.md, .mcp.json, .10xs/) were never committed.
- **Publish:** 20:32 IST, `dart pub publish --force` with Dart 3.13.4 (fvm
  Flutter 3.47.5), at the owner's request ("You do it"). The owner signed in in
  the browser as hireflutterdev@gmail.com. Server: "Successfully uploaded
  https://pub.dev/packages/flutter_ready version 0.1.0". The owner then
  transferred the package to hireflutter.dev. The API shows
  `{"publisherId":"hireflutter.dev"}` and pub points 140/160.
- **Stranger install** on gcp-fleetbox (fresh PUB_CACHE): `dart pub global
  activate flutter_ready` activated 0.1.0. `flutter_ready check` on a lock file
  with flutter_inappwebview 6.1.5 and path_provider 2.1.6:
  `BLOCKER: flutter_inappwebview 6.1.5: No Package.swift in the
  flutter_inappwebview_ios archive.` Exit 1.
- **README:** pub.dev badge added in 0d1cc3e.
