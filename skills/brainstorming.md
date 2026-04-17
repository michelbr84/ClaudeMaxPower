---
name: brainstorming
description: Collaborative design refinement through Socratic questioning before any implementation
arguments:
  - name: topic
    description: Short name or description of what to brainstorm (e.g., "user-auth", "task search feature")
    required: true
  - name: visual
    description: Whether to offer the visual companion for UI-heavy projects (default false)
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

# Skill: brainstorming

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License).
> Original skill: `superpowers:brainstorming`. See `ATTRIBUTION.md` in the project root.

Collaborative design refinement through Socratic questioning. Produces an approved written
spec that later skills (`/writing-plans`, `/subagent-dev`, `/assemble-team`) consume.

## Hard Gate: No Implementation Until Spec Is Approved

This applies to **every project** — even the ones that look "simple." The deliverable of this
skill is a written, reviewed, committed design document. You do not write code, scaffold files,
install dependencies, or run generators during brainstorming. If the user asks you to start
coding mid-session, pause and remind them the spec is the gate.

### Anti-Pattern: "This Is Too Simple To Need A Design"

Every project needs a design. The design does **not** have to be long — it has to be explicit.
A one-line tool still benefits from a paragraph that names the interface, the failure modes,
and the boundary. Scale the design to the complexity of the work, not to your confidence in
being able to skip the step.

| Perceived complexity | Minimum design artifact |
|----------------------|-------------------------|
| Trivial (1 function) | Interface + 2-3 failure modes + one example |
| Small feature        | Above + data flow + test list |
| Module / subsystem   | Above + architecture sketch + component boundaries |
| System / service     | Above + integration points + migration/rollout plan |

## Workflow

### Step 1: Create trackable checklist

Use `TaskCreate` to materialize every step below as a task. The checklist is not optional — it
is how the user can see the gate has been honored.

Tasks to create:

1. Explore project context
2. (If visual) Offer visual companion in its own message
3. Ask clarifying questions one at a time
4. Propose 2-3 approaches with trade-offs and a recommendation
5. Present design in sections, getting approval after each
6. Write design doc to `docs/specs/YYYY-MM-DD-<topic>-design.md` and commit
7. Self-review the written spec
8. Ask the user to review the written spec
9. Transition to `/writing-plans`

### Step 2: Explore project context

Before asking the user anything, understand where you are:

```bash
# Root context
ls -la
cat CLAUDE.md 2>/dev/null
cat README.md 2>/dev/null | head -80
git log --oneline -20
git status
```

Also inspect:

- `package.json` / `pyproject.toml` / `go.mod` — tech stack
- `.claude/agents/` — what agents exist in this project
- `docs/specs/` — any prior specs (so you don't duplicate naming)
- Recent commits touching files related to the topic

Come back to the user with a one-paragraph recap of what you found. This proves you looked.

### Step 3: Offer the visual companion (visual topics only)

If the topic is UI-centric (pages, screens, components, user flows) and `visual` is true,
send a **separate, standalone message** offering the visual companion. Do not combine this
offer with a clarifying question — it needs to be its own decision point so the user can
accept or decline cleanly.

Example message (send alone):

> This is a UI-heavy project. Would you like me to produce visual companions (ASCII wireframes
> or descriptions of layout) alongside the textual spec? Reply "yes", "no", or "later".

### Step 4: Ask clarifying questions — one at a time

Ask **one** question per message. Prefer multiple choice over open-ended. Wait for the answer
before moving on. This is a Socratic dialogue, not an interview script.

```markdown
**Question 1 of ~N.** Who is the primary user of this feature?
  (a) End users of the product
  (b) Internal operators / admins
  (c) Other services (machine-to-machine)
  (d) Something else — please describe
```

Keep going until you have enough to propose approaches. Typical count: 3-8 questions for a
small feature, 8-15 for a subsystem.

### Step 5: Propose 2-3 approaches with trade-offs

Once you understand the problem, present approaches. Each approach gets:

- Name and one-line summary
- How it works (short paragraph)
- Trade-offs (two columns: pros / cons)
- When it's the right choice

End with your recommendation and the reasoning behind it. Then ask the user to pick.

### Step 6: Present the design in sections — approval after each

Do not dump the entire design. Walk through it section by section, scaled to the complexity
tier from the table above:

1. Architecture — the shape of the solution
2. Components — modules, functions, classes, their responsibilities
3. Data flow — inputs, transformations, outputs, state
4. Error handling — failure modes and how each is handled
5. Testing strategy — what is tested, at what layer, with what fixtures

After each section, stop and ask: "Does this match what you want? Anything to change before I
continue?" Do not move on without an explicit yes.

### Step 7: Design for isolation and clarity

Prefer small focused units with clear boundaries. Every component should have:

- A single responsibility you can state in one sentence
- An input contract (types, shape, preconditions)
- An output contract (types, shape, postconditions)
- A documented failure mode

If a component needs more than two sentences to describe, it is probably two components.

### Step 8: Working in existing codebases

When brainstorming inside an existing project:

- Follow the existing patterns — do not invent a new architecture style for a small feature
- Reuse existing abstractions — search for them with `Grep` before proposing new ones
- Do **not** propose unrelated refactoring in the spec. If you spot something that needs
  fixing, note it separately as a follow-up, not as a blocker

### Step 9: Write the spec document

Write to `docs/specs/YYYY-MM-DD-<topic>-design.md`. Use today's date from the environment,
not a placeholder. Structure:

```markdown
# <Feature> — Design

**Status:** Draft / Approved
**Date:** YYYY-MM-DD
**Author(s):** <user>, with Claude

## Problem
## Goals / Non-Goals
## Approaches Considered
## Chosen Approach
## Architecture
## Components
## Data Flow
## Error Handling
## Testing Strategy
## Open Questions
## Follow-Ups (out of scope)
```

Commit the file on a branch (not main):

```bash
git checkout -b spec/<topic>
git add docs/specs/YYYY-MM-DD-<topic>-design.md
git commit -m "docs(spec): add design for <topic>"
```

### Step 10: Self-review before handing to the user

Before asking the user to read the spec, do a pass yourself:

- **Placeholder scan** — grep the file for `TBD`, `TODO`, `XXX`, `???`, `<fill in>`. Fix inline.
- **Internal consistency** — every component referenced in "Data Flow" must be defined in
  "Components". Every error in "Error Handling" must map to a failure mode mentioned earlier.
- **Scope check** — nothing in the spec is out of scope. If it is, move it to "Follow-Ups".
- **Ambiguity check** — read each sentence as if you are the implementer. If a sentence can
  be interpreted two ways, rewrite it.

Fix issues inline. Do not ship a spec with known gaps.

### Step 11: Ask the user to review

Send a clean message pointing at the file:

> The spec is at `docs/specs/YYYY-MM-DD-<topic>-design.md` and committed on `spec/<topic>`.
> Please read it end-to-end. Approve with "approved" or list changes you want.

Wait for explicit approval. Edits requested → apply them → re-request review. Do not proceed
on implicit approval.

### Step 12: Transition to `/writing-plans`

Once the user approves, hand off:

> Spec approved. Transitioning to the `/writing-plans` skill to break this into bite-sized
> implementation tasks. Invoke:
>
> `/writing-plans --spec docs/specs/YYYY-MM-DD-<topic>-design.md`

Transition **only** to `/writing-plans`. Do not jump directly to `/assemble-team`, do not
start implementing, do not spawn subagents. The plan is the next artifact, not the code.

## Key Principles

| Principle | Why |
|-----------|-----|
| One question at a time | The user can answer precisely; you avoid premature commitment |
| Multiple choice preferred | Faster, clearer, surfaces options the user didn't consider |
| YAGNI ruthlessly | Every "nice to have" goes to Follow-Ups, not the spec |
| Explore alternatives | Never ship the first idea without naming at least one other |
| Incremental validation | Approval after each section, not at the end |
| Be flexible | If the user pushes back, update the design. The spec serves them |

## Integration with ClaudeMaxPower

`/brainstorming` produces the spec artifact that feeds the rest of the toolchain:

```
/brainstorming -> docs/specs/*.md
                       |
                       v
/writing-plans -> docs/plans/*.md
                       |
                       v
          /subagent-dev          /assemble-team
          (solo execution)       (parallel team)
```

Both execution paths are valid. Small to medium features usually go through `/subagent-dev`.
Larger, parallelizable work goes through `/assemble-team`. The spec you produce here is
consumed unchanged by either one.
