# QA Validation Doctrine

## Purpose

Define quality assurance standards that ensure deliverables meet user expectations, not just technical specifications. Evidence-based validation is mandatory — claims without proof are rejected.

---

## Core Principle

> If users would be disappointed by the implementation, the deliverable has failed QA — regardless of whether tests pass technically.

---

## Diagnostic Evidence Requirements

When a bug is reported, the Coding Assistant must provide diagnostic evidence **before resubmission**. Writing debugging suggestions is not the same as actual debugging.

### Required Evidence

| Evidence Type | What to Capture |
|---|---|
| Console output | Copy/paste actual logs showing errors, warnings, and state |
| Network inspection | API requests and responses with status codes |
| Server logs | Development console output or production logs |
| Root cause | Specific code reference with explanation |

### Diagnostic Workflow

```
1. Add debugging instrumentation to track the issue
2. Start the development server
3. Reproduce the reported bug with developer tools open
4. Capture actual diagnostic evidence (console, network, logs)
5. Identify and fix the root cause based on evidence
6. Re-test and have PM confirm the fix works
7. Only then resubmit the completion report
```

### Rejection Triggers

- Bug reported but zero diagnostic evidence provided
- "Debugging suggestions" without actual execution
- Submitting with a known blocking bug
- Screenshots showing the bug instead of the working feature

---

## Visual Evidence Standards

### Requirements

- All UI components must have screenshot proof of appearance
- Screenshots must show the **working** implementation, not bugs or loading states
- Visual regression tests with screenshot comparisons are required for UI changes
- Screenshots must exist in the filesystem — not just referenced in reports

### Evidence Quality Checklist

Before capturing any screenshot, verify:

- [ ] Does this screenshot show the specific state being tested?
- [ ] Would a human understand what is being proven by looking at it?
- [ ] Is the relevant data or UI element visible in the screenshot?
- [ ] Could this screenshot serve as evidence in a bug report?

If any answer is "no," the screenshot is meaningless.

---

## Test Planning Protocol

### Before Writing Tests

1. **State the test objective** — What user flow is being validated?
2. **Define expected visual evidence** — What specific UI state should each screenshot capture?
3. **Get stakeholder consent** — Is this the right evidence to prove the feature works?

### After Running Tests

Include in the completion report:

```markdown
## Test Validation

**Tests Executed:**
- Command: {test_command}
- Result: X/Y passing (or X/Y failing with details)
- Execution log: [paste actual output]

**Visual Evidence Provided:**
- {path_to_screenshot_1} (verified exists)
- {path_to_screenshot_2} (verified exists)

**Honest Failure (if applicable):**
- Test #{N} "{description}" — FAILED
- Root Cause: {explanation}
- Fix Required: {what needs to change}
- Status: Implementation incomplete, requires {next_step}
```

---

## Quality Gate Summary

| Gate | Standard | Enforcement |
|---|---|---|
| File length | Target 100 lines, hard limit 200 lines | Pre-commit hook blocks violations |
| Complexity | Cyclomatic complexity per function: 5 or fewer | Linter rule |
| Linting | Zero errors, zero warnings | Pre-commit hook |
| Type safety | Type checker passes with no errors | Pre-commit hook |
| Build | Production build succeeds (exit code 0) | Manual verification |
| Tests | All automated tests pass | Manual verification |
| Visual evidence | Screenshots exist for UI components | Architect review |
| Honest reporting | No false claims of completion | Architect review |