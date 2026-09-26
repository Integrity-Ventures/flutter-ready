# Universal Governance Principles

## Core Standards
- **Evidence over assumption** — every claim must be backed by proof
- **Structured decomposition** — break work into focused, independently executable tasks
- **Session continuity** — preserve context across work sessions so no progress is lost
- **Honest reporting** — report actual status including failures; no false claims of completion
- **Traceability** — every decision and deliverable links back to a requirement
- **Single responsibility** — each task, file, and role has one clear purpose

## Source of Truth — build from the board, not the plan
- `10xs/board/TASKS.json` is the **authoritative list of work to do. Build only what it contains.** It is the current state of the human's board, reconciled after every edit (drop, split, merge, add).
- `10xs/architecture/generated/DECOMPOSITION.json` is the **plan of record** — the immutable, hashed provenance of what was originally generated. Read it for context (acceptance criteria, testing strategy, rationale) but **never treat it as a work list**: the human may have dropped, split or merged tasks since it was produced.
- Each `TASKS.json` entry carries an `origin`. `plan` entries have a matching microtask `id` in `DECOMPOSITION.json` — follow it back for full detail. `split`, `merged` and `added` entries do **not** have a plan counterpart; their detail lives on the entry itself.
- If `TASKS.json` is absent, the board has not been started yet — the Decomposition is then the only plan available.
