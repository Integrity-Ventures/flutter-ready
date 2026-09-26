# Architect gate: read before any card (architect, 2026-09-27)

Workers on this board **never merge into `develop` or `main`** and never
delete branches.

- **Work only in your own clone:** the directory you were launched in
  (`~/flutter-ready/.10xs/plan/<card>`). Never `cd` into `~/flutter-ready`
  itself or edit files there. That tree belongs to the runtime.
- **Run everything in the FOREGROUND and wait for it,** including long live
  runs such as the snapshot job. A print-mode seat that backgrounds a
  command and "waits for the notification" exits at the end of its turn, and
  the work dies uncommitted. That happened to e2-s1 on 2026-09-27.
- **Commit early:** commit to your lane branch after each passing step.

When a card is finished:

1. Push your lane branch (`feature/<card>-<slug>`) to your clone's
   `origin`, which is the local `~/flutter-ready` on the fleetbox. Do **not**
   push to github.com yourself. **Never** configure git credentials, never
   write `~/.git-credentials` or `credential.helper`, and never put a token
   in a remote URL. The architect moves your branch to GitHub. (On
   2026-09-26 at 19:20 UTC a seat's git erased the box's GitHub credential
   through the global `store` helper.)
2. Write your completion report under `10xs/workflow/task_reports/`.
3. push_status the card to `review`. For `artifact_url`, use
   `https://github.com/Integrity-Ventures/flutter-ready/commits/develop`,
   and put your local lane branch name and commit sha in `evidence`. The
   architect then posts the final review with the real `develop` commit URL,
   which supersedes yours. Don't file ask_owner about this (settled by
   the architect, 2026-09-27), and never use the board's bearer-token path
   to push to GitHub yourself.

The architect re-runs `dart analyze --fatal-infos` and `dart test` on the
fleetbox, then squash-merges into `develop`. Scripts under
`~/.flutter-ready-architect/` belong to the architect; don't run them.

Before writing your own instruction file for a card, check this folder
for an architect instruction or note naming your card id. If one exists,
follow it.
