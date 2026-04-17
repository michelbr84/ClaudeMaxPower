---
name: writing-plans
description: Break an approved spec into bite-sized, subagent-executable implementation tasks
arguments:
  - name: spec
    description: Path to approved spec file (e.g., docs/specs/2026-04-17-user-auth-design.md)
    required: true
  - name: output
    description: Custom output path for the plan (default auto-derived from spec filename)
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - TaskCreate
  - TaskUpdate
---

# Skill: writing-plans

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License).
> Original skill: `superpowers:writing-plans`. See `ATTRIBUTION.md` in the project root.

Turn an approved design spec into an executable plan: bite-sized tasks, exact file paths,
complete code expectations, verification steps. The output is designed to be consumed by a
fresh subagent per task (via `/subagent-dev`) — each task must be self-contained because the
subagent will only see the task text, not the whole plan.

## Announce at Start

When this skill is invoked, the **first** message must be, verbatim:

> Using the writing-plans skill to create the implementation plan.

This makes the hand-off visible in the transcript.

## Workflow

### Step 1: Read the spec

Read the file at `$spec`. If it is missing, stop and ask the user for the correct path.
If the spec has `Status: Draft`, stop and tell the user to complete `/brainstorming` first —
plans are only written against approved specs.

### Step 2: Scope check

If the spec covers multiple independent subsystems (e.g., "auth + billing + admin dashboard"),
do **not** produce a single monster plan. Suggest splitting:

> This spec covers three independent subsystems (auth, billing, admin). I recommend writing
> one plan per subsystem so each can be executed and reviewed on its own. Shall I split, or
> keep them merged?

Wait for the user's answer before continuing.

### Step 3: Map the file structure first

Before defining any task, write out which files will be created, modified, or deleted, and
each one's responsibility. This prevents duplicate work and catches integration gaps early.

Example table to include in the plan:

| File | Action | Responsibility |
|------|--------|---------------|
| `src/auth/tokens.py` | create | Token generation + validation |
| `src/auth/middleware.py` | create | Request authentication middleware |
| `src/api/users.py` | modify | Protect `/me` endpoint with middleware |
| `tests/auth/test_tokens.py` | create | Unit tests for tokens |
| `tests/auth/test_middleware.py` | create | Unit tests for middleware |
| `docs/api/auth.md` | create | Public auth API reference |

If a planned file already exists, read it first — the task steps must account for existing
content, not assume an empty file.

### Step 4: Write the plan header

Every plan **must** start with this header (fill in the bracketed parts):

```markdown
# [Feature] Implementation Plan

> **For agentic workers:** REQUIRED: Use `/subagent-dev` (recommended) or `/executing-plans`
> to implement task-by-task. Steps use `- [ ]` checkbox syntax.

**Goal:** [one sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
**Source Spec:** [path to the spec]
```

### Step 5: Bite-sized task granularity

Every task is 2-5 minutes of wall-clock work. Each **step** inside a task is a single action.
The canonical TDD rhythm — applied to almost every task — is:

1. Write the failing test
2. Run it and confirm it fails (RED)
3. Implement the minimal code to make it pass
4. Run the tests and confirm they pass (GREEN)
5. Commit

Each of those is its own checkbox step. Do not collapse them into "implement and test".

### Step 6: Task structure template

Every task uses this exact shape. The example is complete — do not paraphrase, copy it and
replace the content:

````markdown
## Task N: <Imperative task title>

**Files:**
- `src/auth/tokens.py` (create)
- `tests/auth/test_tokens.py` (create)

**Context:** <2-3 sentences on why this task exists and what it unlocks for later tasks.>

**Steps:**

- [ ] 1. Create `tests/auth/test_tokens.py` with the following failing test:

  ```python
  from src.auth.tokens import generate_token, verify_token

  def test_generate_and_verify_roundtrip():
      token = generate_token(user_id=42, ttl_seconds=60)
      payload = verify_token(token)
      assert payload["user_id"] == 42
  ```

- [ ] 2. Run the test and confirm it fails with `ImportError`:

  ```bash
  pytest tests/auth/test_tokens.py -x
  # Expected: ImportError: cannot import name 'generate_token' from 'src.auth.tokens'
  ```

- [ ] 3. Create `src/auth/tokens.py` with:

  ```python
  import jwt
  from datetime import datetime, timedelta, timezone

  SECRET = __import__("os").environ["AUTH_SECRET"]

  def generate_token(user_id: int, ttl_seconds: int) -> str:
      exp = datetime.now(timezone.utc) + timedelta(seconds=ttl_seconds)
      return jwt.encode({"user_id": user_id, "exp": exp}, SECRET, algorithm="HS256")

  def verify_token(token: str) -> dict:
      return jwt.decode(token, SECRET, algorithms=["HS256"])
  ```

- [ ] 4. Run the tests and confirm they pass:

  ```bash
  pytest tests/auth/test_tokens.py -v
  # Expected: 1 passed in <1s
  ```

- [ ] 5. Commit:

  ```bash
  git add src/auth/tokens.py tests/auth/test_tokens.py
  git commit -m "feat(auth): add token generate/verify"
  ```

**Done when:**
- `pytest tests/auth/test_tokens.py` is green
- `src/auth/tokens.py` exports `generate_token` and `verify_token`
- Commit is on the feature branch
````

Every task you write must include:

- Explicit file list with action (`create` / `modify` / `delete`)
- Short context paragraph
- Checkbox steps, each with the code **in full** and the exact command + expected output
- A "Done when" section that a reviewer can verify mechanically

### Step 7: No Placeholders — the banned phrases list

The following must never appear in a plan. If the urge strikes to write one of these, stop
and write the real content instead:

| Banned | Why it fails |
|--------|--------------|
| `TBD`, `TODO`, `implement later` | Subagent has no context to fill these in |
| "Add appropriate error handling" | Which errors? Which handling strategy? |
| "Write tests for the above" (no code) | Subagent won't know which cases matter |
| "Similar to Task N" | The subagent may read tasks out of order or not at all |
| Steps without a code block | Every step has either commands or source code |
| References to undefined types / functions | If it's new, define it in an earlier task first |
| "Follow the existing pattern" with no example | Paste the pattern inline |
| "Update the tests" | Which tests? Paste them |

Repeat code across tasks when needed. The plan can be long — that is fine. Long is better
than ambiguous.

### Step 8: Self-review checklist

Before marking the plan ready, walk this checklist. Fix issues **inline**; do not ship
a plan that fails any item:

- **Spec coverage** — every requirement in the spec maps to at least one task. Make a
  mental cross-reference pass section by section.
- **Placeholder scan** — grep the plan file for the banned phrases from Step 7:

  ```bash
  grep -nE 'TBD|TODO|FIXME|XXX|implement later|similar to task|appropriate error handling' \
    docs/plans/<plan>.md && echo "FOUND PLACEHOLDERS — FIX BEFORE SHIPPING"
  ```

- **Type consistency** — every function signature referenced in task N is defined in task
  ≤ N. Imports point at files that have been created in earlier tasks.
- **Command reproducibility** — every bash command assumes a known working directory and
  lists its expected output.
- **Commit discipline** — every task ends with a commit. No task lumps unrelated work into
  one commit.

### Step 9: Write the plan file

Default path: if `output` is unset, derive from the spec path. E.g.:

```
docs/specs/2026-04-17-user-auth-design.md
  -> docs/plans/2026-04-17-user-auth-plan.md
```

Commit on the same branch as the spec (or a dedicated `plan/<topic>` branch):

```bash
git add docs/plans/YYYY-MM-DD-<topic>-plan.md
git commit -m "docs(plan): add implementation plan for <topic>"
```

### Step 10: Execution handoff

End your message to the user with the two supported execution paths:

> Plan is at `docs/plans/YYYY-MM-DD-<topic>-plan.md`. Two execution choices:
>
> 1. `/subagent-dev --plan docs/plans/YYYY-MM-DD-<topic>-plan.md` — recommended for most
>    features. Fresh subagent per task, two-stage review, everything in this session.
>
> 2. `/assemble-team --mode existing-project --goals "<topic>"` — use when tasks are
>    independent and benefit from running in parallel across multiple agents.
>
> Pick one when you're ready.

## Integration with ClaudeMaxPower

`/writing-plans` is the bridge between `/brainstorming` and execution:

```
/brainstorming -> spec
      |
      v
/writing-plans -> plan
      |
      +--> /subagent-dev   (serial, current session, two-stage review)
      |
      +--> /assemble-team  (parallel, worktree-isolated team)
```

The plan file is the single source of truth consumed by both execution paths. Never modify
the plan after execution starts — open a new plan revision instead.
