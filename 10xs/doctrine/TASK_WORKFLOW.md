# Task Workflow Doctrine

## Purpose

Define the structured workflow for planning, executing, and validating work using governance-enforced microtasks. Three roles collaborate in a closed loop.

---

## Workflow Model

```
Architect creates microtask instruction
    |
Coding Assistant executes microtask
    |
Coding Assistant submits completion report
    |
Phase 4 validation (see below: connected machine or human-only)
    |
Approve or Reject -> Next microtask
```

---

## Phase 1: Microtask Assignment (Architect -> Coding Assistant)

### Instruction File

Create instruction files following the naming convention:

```
{governance}/workflow/instructions/{YYYYMMDD}_{##}_{taskname}.md
```

### Required Sections

| Section | Content |
|---|---|
| Objective | What must be accomplished and why |
| Context | Current state, dependencies, constraints |
| Implementation Steps | Specific steps with file references |
| File Scope | Which files to create or modify (max 5 implementation files) |
| Acceptance Criteria | Measurable conditions for approval |
| Testing Strategy | How to validate the implementation |

### Size Constraints

- Maximum 5 implementation files (tests/configs excluded)
- Maximum 2-3 core modules with single responsibility
- Maximum 1 week development time
- Each microtask targets one functional area

---

## Phase 2: Task Execution (Coding Assistant)

### Before Starting

1. Read the instruction file completely
2. Read referenced code to understand existing patterns
3. Plan modular architecture before implementation
4. Validate the plan meets file size constraints

### During Execution

1. Implement incrementally — validate file length after each module
2. Extract utilities when approaching 80-100 lines
3. Stop immediately at 150 lines and refactor
4. Run linter and type checker frequently

### Before Completion

Run the full pre-completion validation checklist:

1. Linter passes with zero errors
2. Type checker passes
3. All automated tests pass
4. All implementation files within line limits
5. Production build succeeds
6. Pre-commit hooks pass
7. Visual evidence captured for UI components

---

## Phase 3: Completion Report (Coding Assistant -> PM)

### Report Location

```
{governance}/workflow/task_reports/{task_id}_report.md
```

### Required Content

- Work completed (files created/modified with line counts)
- Automated test results with pass/fail evidence
- Screenshot evidence for visual components
- Build verification (exit code 0)
- Known issues or limitations (honest reporting)
- Suggested commit message

The completion report itself is always full — it is evidence, not a message to the PM (see below).

---

## Communicating With The PM

## Talking To The Project Manager

Chat replies, cross-session messages, "needs you" cards, directives, and status notifications
addressed to the project manager **lead with a plain-language summary of four lines or fewer** —
what happened, what you need from them. Full detail only on request.

**Exempt: documentation.** Microtask instructions, completion reports, session handoffs, round
records, and deploy records stay full, because they are evidence.

**A message is compressed; evidence is not.**

This applies to how any role addresses the PM directly, at any phase — it does not shorten the
instruction file, the completion report, or any other document named in this workflow.

---

## Phase 4: Validation & Approval

### With a connected machine

A project with a connected machine completes this phase without a person in the loop.

1. The Architect validates the deliverable against the acceptance criteria
2. The Architect pushes the card to `review` **with evidence** — the completion report, test output, and the commit sha
3. The board's checker grades the card and writes `done`, or sends it back with a reason the Architect pulls as a directive
4. A person enters only by exception: a "Needs you" flag when the board's checker cannot decide, and at sprint close to accept the batch against the test guide

### Without a connected machine

A project with no connected machine keeps this phase person-reviewed, as it always has.

1. PM reviews the completion report and evidence
2. PM provides summary to Architect
3. Architect validates against acceptance criteria
4. Architect scores the deliverable (1-10 scale)
5. **Approve**: Update documentation, create next microtask
6. **Reject**: Provide specific feedback for resubmission

### Rejection Triggers

- Claims of success without test evidence
- File length violations without acknowledgment
- Known bugs submitted as "complete"
- Missing visual evidence for UI components

---

## Git Operations

- A lone connected agent runs the full sequence: claim, write the instruction as Architect, execute it as
  Coding Assistant, write the completion report, push_status with instruction_ref, then submit for review
- The agent may commit and push its feature branch so the report can cite evidence
- PM handles approval, merge, and protected-branch operations
- Feature branches created from the development branch for every task
- Squash merge to development branch after approval

### Commit Attribution (RULED, PM R1 — applies to whoever commits, not to a role)

The rule above describes the three-role model. It says nothing about attribution, and a single connected agent that commits directly needs that rule before its first commit. So, regardless of role: if you make a commit in this repository, it must carry a `Co-Authored-By:` trailer identifying this project's commit-attribution identity. This is a commit-message trailer ONLY — never set the git author or committer identity to it, never run `git config user.name` or `git config user.email`, never pass `--author`.

The default identity is `10xs.ai`. A project may override it (see `commitAttribution` on the `get_board` MCP response). This file is a static template, frozen into your repo once at clone time — it cannot see a later change to that setting. When the live `get_board` response's `commitAttribution` differs from the default named here, the board is AUTHORITATIVE, not this text.