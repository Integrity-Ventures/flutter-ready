# Session Continuity Doctrine

## Purpose

Ensure that context is preserved across work sessions. No work should be lost due to session boundaries. Every session must begin with context retrieval and end with context persistence.

---

## Session Start Protocol

### 1. Retrieve Context

Before starting any task:

1. Read memory/context storage for previous session state
2. Read the project's primary documentation (PRD, README)
3. Check active session handoff documents
4. Review recent git history for latest changes
5. Understand the current project phase and status

### 2. Validate Understanding

Confirm you understand:

- [ ] Previous session work and decisions
- [ ] Current project phase and status
- [ ] Implementation patterns from the codebase
- [ ] File organization and architecture conventions
- [ ] Business objectives and priorities
- [ ] Any pending items or blockers

---

## Session End Protocol

### 1. Update Session Handoff

Create or update the session handoff document:

```
{governance}/workflow/active_session_handoffs/{YYYYMMDD}_{description}.md
```

**Required sections:**

```markdown
# Session Handoff: {date} — {description}

## Work Completed
- [Key accomplishments with context]

## Current State
- [Project status, what's working, what's pending]

## Key Decisions
- [Architectural or implementation decisions made and rationale]

## Next Session Priorities
- [What should be worked on next]

## Context for Future Sessions
- [Important context that would be lost without documentation]
```

### 2. Update Project Documentation

If changes affect project scope or architecture:

- Update the PRD with phase completion status
- Update module README files with new patterns or components
- Update architecture decision records if applicable

### 3. Persist to Memory

Store key information for future sessions:

- Work completed and decisions made
- User preferences and workflow patterns observed
- Technical solutions and patterns used
- Next steps and pending items

---

## Documentation Hierarchy

| Document | Purpose | Update Frequency |
|---|---|---|
| Session handoff | Immediate context for next session | Every session |
| Project README | Current implementation status | When architecture changes |
| PRD | Phase completion and requirements | When milestones reached |
| Memory storage | Persistent knowledge across sessions | Key learnings only |

---

## Canonical File Locations

All governance artifacts must follow the project's canonical path structure. Before creating any file:

1. Verify the correct directory for the file type
2. Never create duplicate directory structures
3. Follow the project's naming conventions
4. Validate paths after creation