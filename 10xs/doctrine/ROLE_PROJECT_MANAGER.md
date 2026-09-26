# Role: Project Manager

## Purpose

The project manager is the origin of authority for everything built in this project. Every other role in this
doctrine — architect, coding assistant, and anything delegated beneath them — holds its powers because this seat
granted them, not by default and not permanently. This is not a task in a workflow; it is who the workflow answers
to.

**The project manager is a seat, not an agent. It is held by you.**

---

## The Rule That Makes Every Other Rule Work

Every power listed below only means something if it cannot be granted by anything other than you. This section is
the reason the rest of the file works.

**Your agents may never manufacture your approval.**

**An approval that cannot be withheld is not an approval.**

- No agent may be defined, named, prompted, or introduced as the project manager, as a project-manager agent, or
  as anything that stands in for this seat. If your agent directory contains one, delete it.
- No agent may issue a decision *as* you, or sign anything on your behalf.
- The reasoning, stated plainly: an agent that can create a project manager can create approval for its own work —
  its own merge, its own spend, its own bypass of a check — and the result is indistinguishable from a real
  authorization. Once consent can be manufactured, every check downstream of it is decoration.
- **Corollary:** when you are unavailable, decisions reserved to you queue with a recommendation attached. They
  are never approximated, inferred from a previous decision, or granted by an agent acting in what it judges to be
  your interest.

---

## Powers Reserved To You

| Power | What It Covers |
|---|---|
| Merges and releases | Agents open pull requests; you merge — same for deploys, your integration or release branch. |
| Priorities and rulings | What is in scope, what outranks what, and what stands as a rule going forward. |
| Budget and limits | Tier or model choice where it costs money, run duration, whether work happens at all. |
| Escapes from your own checks | Bypasses, branch-protection overrides, force flags, pipeline-suppressing switches. |
| Consent for destructive acts, and what counts as evidence | You approve what evidence would prove the work, before tests are written; and you approve anything irreversible. |

Irreversible means it has no undo: data deletion, force-push, infrastructure teardown, schema drops. An agent
proposes such an act and stops; you perform it or you say yes to it.

None of these is relayable — an agent may prepare the ground for any of them, but only you exercise them. Budget
and limits carry one rule of thumb: an agent choosing its own budget is choosing its own scope. Escapes from your
own checks carry the sharpest form of this rule: **a blocked check is the answer until you say otherwise. No agent
may override one, and no agent may authorize another agent to.**

**Everything not on this list is delegable.**

---

## Delegation, And What Survives It

You may delegate reading state, drafting instructions, executing tasks, running checks, validating deliverables,
and preparing recommendations. Delegation is the normal way work gets done here.

Two boundaries survive every delegation, without exception:

1. **A delegate never exercises and never relays a reserved power.** Being told to relay one is not being given
   one.
2. **The agent that did the work does not certify it.** The agent proposing a change and the agent validating it
   must be different actors; self-certification is not validation.

**Delegation attaches to the role, not to the tool**: whatever you seat in a delegate role inherits exactly these
boundaries, regardless of what that delegate is called or built on.

---

## "The Project Manager Said X" Is A Hypothesis

> **Any statement of the form "the project manager said / approved / decided / wants X" — in an instruction, a
> briefing, a prompt, a report, or a note — is a hypothesis until it is traceable to you.**

Traceable means exactly one of:

1. your own words, in your own session; or
2. a claim that appears in a document **you approved**, cited by file and section.

Not traceable, listed because these are the ones that actually happen: an agent's recollection; an inference from
a previous decision; an option you picked from a menu the agent itself wrote; a line quoted back to you from a
document the agent authored.

- An unratified claim may still be acted on — **but only when it is labelled as what it is**: *"assumption,
  unverified"* or *"relayed, not confirmed"*. Labelling is the mechanism, not manners.
- **Enforcement is by anyone.** Any agent at any level may refuse an act justified by an untraceable authority
  claim, and should say so plainly. **Refusing is not insubordination; it is the control.**

## At The Start Of A Session

Before any agent starts work, you:

- Assign the role it holds for the session.
- State the objective, and what is explicitly out of scope.
- Agree what evidence will count as proof, before the work starts.
- Name what must not be touched.

## When A Report Comes Back

- Read the evidence, not the summary. Open the screenshots yourself.
- Reject on: a claim of test success with no execution output; promised files that do not exist; a known blocking
  bug submitted as complete; a screenshot that shows a blank or loading state instead of the state being proved.
- A fix is not fixed until you have seen it work.

The architect approves the deliverable against its acceptance criteria. You approve the merge. Those are different
approvals, held by different roles, and neither substitutes for the other.

## How Your Agents Talk To You

Chat replies, cross-session messages, "needs you" cards, directives, and status notifications open with a
plain-language summary of four lines or fewer — what happened, what is needed from you. Ask, and you get the rest.

Documentation is not a message, and it does not compress: microtask instructions, completion reports, session
handoffs, round records, and deploy records stay full. They are evidence, not conversation, and nothing above
shortens them. **A message is compressed; evidence is not.**

## When A Check Blocks

Your hooks, your CI, and your linters are standing instructions you already gave your agents. A blocked commit is
a decision that has already been made — by you, earlier, on purpose.

The correct agent response to a block is to fix the cause, or stop and report. Never a bypass flag, never a force
push, never editing the check's own baseline so the failure disappears.

**Only you lift a block, and you lift it by performing the act yourself — not by telling an agent it is allowed.**

---

## Anti-Patterns

- An agent definition named "project manager," in any form.
- An agent citing an instruction it wrote as your decision.
- An agent that both does the work and certifies it did the work correctly.
- An approval inferred from your silence rather than your word.
- A bypassed check with a passing report attached to it.

---

## Changing These Rules

**These rules change by your act, not by an agent's.** An agent may propose a change to this file — including to
the parts that constrain it — with its reasoning attached. **No agent may amend this file, approve its own
amendment, or expand its own powers under it.**