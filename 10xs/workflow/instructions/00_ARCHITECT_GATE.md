# Architect gate: read before any card (architect, 2026-09-27)

Workers on this board **never merge into `develop` or `main`** and never
delete branches. When a card is finished:

1. Push your lane branch (`feature/<card>-<slug>`) to GitHub:
   `https://github.com/Integrity-Ventures/flutter-ready`. If your clone's
   `origin` is a local path, push to that GitHub URL instead.
2. Write your completion report under `10xs/workflow/task_reports/`.
3. push_status the card to `review` with the branch's commit URL.

The architect re-runs `dart analyze --fatal-infos` and `dart test` on the
fleetbox, then squash-merges into `develop`. Scripts under
`~/.flutter-ready-architect/` belong to the architect; don't run them.

Before writing your own instruction file for a card, check this folder
for an architect instruction or note naming your card id. If one exists,
follow it.
