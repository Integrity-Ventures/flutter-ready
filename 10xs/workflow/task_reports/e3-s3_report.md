# Completion Report: e3-s3 — Deployment (architect)

## Done (2026-09-27)
- The owner said to merge develop into main: fast-forward e919606..4387727
  (37 commits). amplify.yml landed at 0b7b840 and docs at 3380840, on both
  branches. CI and Verify Action are green on 4387727.
- `amplify.yml` at the repo root: downloads Dart 3.13.4, activates
  jaspr_cli 0.23.5, runs `jaspr build` in `site/`, and publishes
  `site/build/jaspr`. No secrets; one build for all branches.
- The owner created the Amplify app `flutter-ready` (appId d1rgrd4z45pwk3,
  us-east-1, platform WEB, repo Integrity-Ventures/flutter-ready, branch
  main) in the console. A CLI create had failed because the Integrity-Ventures
  org disables deploy keys and the Amplify GitHub App wasn't installed; the
  console flow installs it.
- First Amplify job (job 1): BUILD, DEPLOY and VERIFY all SUCCEED (read with
  `aws amplify list-jobs/get-job --profile ivp-10xs`).
- Live checks (curl) on https://main.d1rgrd4z45pwk3.amplifyapp.com/:
  - `/` → 200, "Top 100 plugins"
  - `/p/url_launcher/` → "Package.swift found in the url_launcher_ios archive"
  - `/p/path_provider/` → "Not affected: no native iOS code"
  - `/p/in_app_update/` → "Not affected: not an iOS plugin"

## Remaining (owner)
- The DNS record for ready.hireflutter.dev pointing at the Amplify app (the
  owner handles it; add the custom domain in Amplify's Domain management).
- The nightly snapshot workflow now runs from main at 02:00 UTC; the first
  scheduled run is the next thing to check.
