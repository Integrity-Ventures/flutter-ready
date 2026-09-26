# Clean Architecture Doctrine

## Purpose

Define file length, complexity, and structural standards that keep code maintainable, testable, and reviewable. These standards apply to all new and refactored code.

---

## File Length Standards

| Zone | Lines | Action |
|---|---|---|
| Excellence | 50 or fewer | Ideal single responsibility |
| Target | 100 or fewer | Preferred for new code |
| Warning | 100-150 | Consider refactoring |
| Hard Limit | 200 | Must not exceed (enforced by pre-commit) |

**Tests are exempt** from file length limits — test files may exceed 200 lines.

---

## Complexity Standards

### Function Level

| Metric | Limit | Rationale |
|---|---|---|
| Cyclomatic complexity | 5 or fewer | Keeps branching manageable |
| Function length | 50 lines or fewer | Encourages decomposition |
| Parameters | 4 or fewer | Use config objects for more |
| Nesting depth | 3 levels or fewer | Prevents deep conditionals |

### File Level

| Metric | Limit |
|---|---|
| Functions per file | Target 5 or fewer |
| File responsibilities | Exactly 1 clear purpose |
| Public exports | Minimize surface area |

---

## Refactoring Triggers

Act immediately when any of these conditions are met:

1. **File approaching 150 lines** — Extract utilities, hooks, or components
2. **Function exceeding 15 lines** — Break into smaller functions
3. **Nesting deeper than 2 levels** — Simplify conditional logic
4. **Duplicated logic across files** — Extract shared utilities
5. **More than 3 parameters** — Use configuration objects

---

## Decomposition Patterns

When a file grows beyond targets, extract in this order:

| Pattern | Target Location | Content |
|---|---|---|
| Constants | `lib/constants.{ext}` | Configuration values, magic numbers |
| Utilities | `lib/utils.{ext}` | Pure functions, helpers |
| Types | `lib/types.{ext}` | Interfaces, type definitions |
| Hooks/Services | `hooks/` or `services/` | Stateful logic, side effects |
| Components | `components/` | UI building blocks |

The main file retains only orchestration logic — under 100 lines.

---

## Principles

### Do

- **Plan modular architecture before implementation** — not after
- **Extract early** at 80-100 lines, not at 200
- **Prefer composition** — build from small, focused pieces
- **Write pure functions** — stateless, testable, no side effects
- **Validate incrementally** — check file length after every major addition

### Do Not

- **Do not over-engineer** — only add what is directly needed
- **Do not add features beyond what was asked** — a bug fix does not need refactoring
- **Do not add error handling for impossible scenarios** — trust internal code
- **Do not create abstractions for one-time operations** — three similar lines are fine
- **Do not add comments, docstrings, or type annotations to unchanged code**

---

## Evolution Strategy

```
Phase 1: All files comply with 200-line hard limit
Phase 2: Most files target 100-line preferred zone
Phase 3: Excellence — files at 50 lines, single responsibility
```