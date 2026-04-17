---
name: subagent-dev
description: Execute a plan with a fresh subagent per task and two-stage review (spec then quality)
arguments:
  - name: plan
    description: Path to the plan file produced by /writing-plans
    required: true
  - name: worktree
    description: Whether to require git worktree isolation (default true)
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
  - TaskCreate
  - TaskUpdate
---

# Skill: subagent-dev

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License).
> Original skill: `superpowers:subagent-driven-development`. See `ATTRIBUTION.md` in the project root.

Execute a plan task-by-task using a fresh subagent for each implementation, followed by a
two-stage review: spec compliance first, then code quality. This keeps each subagent's
context small and focused, and separates "did you build what the spec asked for" from "is
the code any good" so neither review contaminates the other.

## Announce at Start

The first message this skill emits must be, verbatim:

> I'm using subagent-driven development to execute this plan.

## Core Principle

**Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration.**

A single long-lived session drifts, rationalizes, and accumulates irrelevant context. A fresh
subagent per task stays focused, cannot cut corners in one task to "save time" for another,
and gives you a natural checkpoint between steps. The two-stage review prevents the common
failure mode where a reviewer approves beautiful code that does the wrong thing.

## When To Use vs. Alternatives

| Choice | Use when |
|--------|----------|
| `/subagent-dev` (this skill) | You have a plan and want controlled, reviewed execution in the current session |
| `/executing-plans` in another session | You want a separate Claude session to run the plan end-to-end unattended |
| Manual implementation | One or two trivial tasks where review overhead is more than the work |

## Workflow

### Step 1: Preconditions

Before starting:

- **Worktree** — if `worktree` is true (default), require an isolated worktree. If not
  already in one, tell the user to invoke `/using-worktrees` (or the
  `superpowers:using-git-worktrees` skill) and stop. Do **not** start on `main` / `master`
  without explicit user consent.
- **Clean tree** — `git status` must be clean or the user must acknowledge the diff.
- **Plan readable** — verify `$plan` exists and parses as a plan (has the plan header and at
  least one `## Task` section).

### Step 2: Read the plan ONCE, extract all tasks

The controller (this session) reads the plan file exactly once. Extract, for each task:

- Task number and title
- Full task text (Files, Context, Steps, Done when)
- Any cross-task context the task depends on

Create a `TaskCreate` entry for every task in the plan. The task list is how you, the user,
and the subagents keep score.

**Subagents will not read the plan file.** The controller passes full task text to each
subagent. This is deliberate: it prevents subagents from reading ahead, working out of order,
or being influenced by tasks that are not theirs.

### Step 3: Per-task loop

For each task, in order:

#### 3a. Dispatch the implementer subagent

Give the implementer the full task text plus any needed cross-task context (e.g., function
signatures from earlier tasks). Use the prompt template in the "Prompt Templates" section.

Do **not** parallelize implementer subagents. They write files, and file-level conflicts
(even with worktrees) are expensive to resolve in the middle of a review cycle.

#### 3b. Answer implementer questions before it proceeds

If the implementer responds with `NEEDS_CONTEXT` or asks a clarifying question, answer it
from the plan / spec. Do **not** tell the implementer to "guess" or "use your judgment" on
anything load-bearing. If the answer isn't in the plan, stop the whole loop and escalate to
the user.

#### 3c. Implementer implements, tests, commits, self-reviews

The implementer is expected to follow the task's steps, run the task's verification commands,
commit, and report one of the four statuses defined in "Handling Implementer Status".

#### 3d. Dispatch the spec compliance reviewer

**Only** after the implementer reports `DONE` or `DONE_WITH_CONCERNS`, dispatch the spec
compliance reviewer. This subagent is given:

- The task text (not the plan)
- The diff of what the implementer changed
- The relevant spec sections

The reviewer answers one question: **did this diff implement the task as specified?** It
does not comment on code style, naming, or test patterns. Those are for stage two.

If spec compliance finds issues → dispatch a fresh implementer subagent to fix them → re-run
spec compliance review → loop until the spec reviewer returns ✅.

#### 3e. Only after spec ✅: dispatch the code quality reviewer

Now, and only now, dispatch the code quality reviewer. It sees the same diff but looks at:

- Readability and naming
- Error handling quality
- Test coverage and assertion strength
- Duplication / dead code / unused imports
- Project convention compliance

If code quality finds issues → fresh implementer subagent to fix → spec review is **not**
re-run because the contract is unchanged → code quality re-review → loop until ✅.

#### 3f. Mark the task complete

Use `TaskUpdate` to mark the task completed, with a short note on the commit SHA and any
concerns carried forward.

### Step 4: Next task

Move to the next task in the plan. Do not skip. Do not reorder unless a task explicitly
depends on a later one and the plan is wrong — if that happens, stop and update the plan.

### Step 5: Final pass — whole-implementation review

After every task is complete, dispatch a **final code reviewer** subagent over the full
feature branch diff (not just the last task). This catches integration issues that per-task
review cannot see: interactions between modules, overall architecture drift, missing
cross-cutting concerns (logging, metrics, docs).

Issues found here → fresh implementer subagent → re-dispatch the final reviewer → loop until
the final reviewer returns ✅.

### Step 6: Finish the branch

Hand off to `/finish-branch` (or the `superpowers:finishing-a-development-branch` skill). It
presents the integration options: PR, merge, rebase, squash, or abandon.

## Model Selection

Different tasks benefit from different model tiers. Pick per-subagent:

| Task shape | Model tier | Example |
|------------|------------|---------|
| Mechanical (1-2 files, clear spec) | Cheap / fast | "Rename function and update imports" |
| Integration / judgment | Standard | "Wire middleware into request pipeline" |
| Architecture / design / review | Most capable | Final reviewer, spec reviewer on complex tasks |

Reviewers generally get the most capable model available. Implementers can drop tiers if the
task is small and mechanical.

## Handling Implementer Status

Every implementer subagent must return one of four statuses. Handle each:

| Status | Meaning | Controller response |
|--------|---------|---------------------|
| `DONE` | Task steps complete, tests pass, commit made | Proceed to spec review |
| `DONE_WITH_CONCERNS` | Task done, but the implementer flagged risks or surprises | Proceed to spec review; surface concerns to the user after the task closes |
| `NEEDS_CONTEXT` | Task text insufficient — implementer cannot proceed without more info | Answer from plan/spec; if unanswerable, escalate to user; never ask the subagent to guess |
| `BLOCKED` | External failure (test infra broken, dependency missing, etc.) | Stop the loop, surface the blocker to the user, do not fake progress |

## Red Flags — never do these

| Red flag | Why it's bad |
|----------|--------------|
| Start on `main` / `master` without user consent | Dirties the trunk with unreviewed partial work |
| Skip spec or code quality review | The two-stage review is the value prop of this skill |
| Dispatch multiple implementer subagents in parallel | They will conflict on files, commits, and branch state |
| Make the subagent read the plan file | Causes lookahead, out-of-order work, and scope creep |
| Start code quality review before spec compliance ✅ | Quality review becomes noise; style feedback drowns correctness |
| Let `DONE_WITH_CONCERNS` silently promote to `DONE` | Concerns must be surfaced to the user |
| Fake progress when `BLOCKED` | Blocks become bigger the longer they're hidden |

## Prompt Templates

These are the inline templates the controller uses when dispatching subagents. Substitute the
bracketed fields.

### Implementer prompt

```
You are the implementer subagent for Task [N] of the [feature] implementation plan.

You are given the full task text below. Do NOT read the plan file. Do not read other task
texts. Your scope is exactly this task.

Follow the steps in order. Run every verification command the task specifies. Commit at the
end if the task calls for it.

Return one of:
  DONE                — Task complete, tests green, commit made: <sha>
  DONE_WITH_CONCERNS  — As DONE, plus a list of concerns for the controller to surface
  NEEDS_CONTEXT       — Missing information; specify exactly what
  BLOCKED             — External failure; specify the blocker

TASK TEXT:
---
[full task text from the plan]
---

CROSS-TASK CONTEXT YOU MAY NEED:
---
[function signatures, types, or file paths from earlier tasks]
---

Working directory: [worktree path]
Branch: [branch name]
```

### Spec compliance reviewer prompt

```
You are the spec compliance reviewer for Task [N].

Your ONLY question: does this diff implement the task as specified? You do not comment on
code style, naming, testing patterns, or quality. Those are for a later stage.

Return:
  SPEC_OK    — Diff matches the task's Files, Steps, and Done-when criteria
  SPEC_FAIL  — List each deviation with file:line and what the spec requires

TASK TEXT:
---
[full task text]
---

RELEVANT SPEC SECTIONS:
---
[excerpt from docs/specs/...]
---

DIFF:
---
[git diff for this task's commit(s)]
---
```

### Code quality reviewer prompt

```
You are the code quality reviewer for Task [N]. Spec compliance has already been confirmed —
do not re-check spec compliance.

Evaluate:
  - Readability and naming
  - Error handling (explicit, correct, not swallowed)
  - Test coverage and assertion strength
  - Duplication / dead code / unused imports
  - Project convention compliance (see CLAUDE.md)

Return:
  QUALITY_OK    — Ship it
  QUALITY_FAIL  — List each issue with file:line, severity (blocker/major/minor), and the fix

TASK TEXT:
---
[full task text]
---

DIFF:
---
[git diff for this task's commit(s)]
---

PROJECT CONVENTIONS (excerpt):
---
[relevant lines from CLAUDE.md]
---
```

## Integration with ClaudeMaxPower

`/subagent-dev` is the serial, reviewed execution path:

```
/brainstorming -> spec
/writing-plans -> plan
      |
      v
/subagent-dev  (this skill)
      |
      v
/finish-branch -> PR / merge
```

It pairs with `/using-worktrees` at the start and `/finish-branch` at the end. For
parallelizable work where independent tasks can run concurrently, use `/assemble-team`
instead — it uses a similar review discipline but spawns multiple implementers across
worktrees.
