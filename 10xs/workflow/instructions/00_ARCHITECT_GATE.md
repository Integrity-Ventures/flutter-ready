# Architect gate: read before any card (architect, 2026-09-27)

Workers on this board **never merge into `develop` or `main`** and never
delete branches. When a card is finished:

1. Push your lane branch (`feature/<card>-<slug>`) to your clone's
   `origin`, which is the local `~/flutter-ready` on the fleetbox. Do **not**
   push to github.com yourself. **Never** configure git credentials, never
   write `~/.git-credentials` or `credential.helper`, and never put a token
   in a remote URL. The architect moves your branch to GitHub. (On
   2026-09-26 at 19:20 UTC a seat's git erased the box's GitHub credential
   through the global `store` helper.)
2. Write your completion report under `10xs/workflow/task_reports/`.
3. push_status the card to `review` with the branch's commit URL.

The architect re-runs `dart analyze --fatal-infos` and `dart test` on the
fleetbox, then squash-merges into `develop`. Scripts under
`~/.flutter-ready-architect/` belong to the architect; don't run them.

Before writing your own instruction file for a card, check this folder
for an architect instruction or note naming your card id. If one exists,
follow it.
