# 20 — Workflow

Session start protocol, the unified pipeline, and the alternate entry points used when the
full pipeline would add more friction than value.

## Session Start Protocol

At the start of every session:

1. Check if `.estado.md` exists in the project root. If it does, read it to restore context.
   (`.estado.md` is written by the `stop` hook and surfaced by the `session-start` hook —
   see [`../docs/hooks-guide.md`](../docs/hooks-guide.md).)
2. Check if `.env` exists. If it does not, warn the user and suggest running
   `bash scripts/setup.sh`.
3. Identify which area of the project you are working in (hooks / skills / agents / examples
   / docs).
4. If the user's goal is ambiguous and involves any new feature, default to the pipeline:
   **brainstorm → spec → plan → execute → review → finish**.

## The Unified Pipeline (Superpowers + ClaudeMaxPower)

The methodology skills (brainstorming, plans, TDD, debugging, worktrees, finish) live
upstream in the Superpowers plugin. Install with:

```
/plugin install superpowers@claude-plugins-official
```

Invoke them with the `/superpowers:*` namespace. ClaudeMaxPower keeps a thin
`/superpowers-redirect` skill that catches the old slash commands and points users to the
canonical replacements — see [40-skills.md](40-skills.md).

```
Idea
 ├─ /superpowers:brainstorming                      → docs/specs/YYYY-MM-DD-<topic>-design.md (hard gate)
 ├─ /superpowers:writing-plans                      → docs/plans/YYYY-MM-DD-<topic>-plan.md
 ├─ /superpowers:using-git-worktrees                → isolated branch workspace
 ├─ /superpowers:subagent-driven-development        → fresh subagent per task + two-stage review
 │    └─ /superpowers:test-driven-development           (strict Red-Green-Refactor, iron law)
 │    └─ /superpowers:systematic-debugging              (root cause before fix)
 └─ /superpowers:finishing-a-development-branch     → merge / PR / keep / discard + worktree cleanup
```

Each iron law in [10-iron-laws.md](10-iron-laws.md) is enforced at a specific step of the
pipeline.

## Alternate Entry Points

When the full pipeline would add more friction than value, use one of the native
ClaudeMaxPower skills:

| Situation | Entry point |
|---|---|
| Existing GitHub issue | `/fix-issue` (escalates to `/superpowers:systematic-debugging` if stuck) |
| Structured PR review | `/review-pr` |
| Architectural refactor | `/superpowers:brainstorming` + `/superpowers:writing-plans` |
| Simple refactor | `/refactor-module` |
| Team pattern for large features | `/assemble-team` (enforces brainstorming gate in new-project mode) |
| Conventional Commits message | `/gen-commit-message` (the deterministic pre-commit checks now run automatically via `.claude/hooks/pre-commit-check.sh`) |
| One-command bootstrap | `/max-power` (installs, configures, presents menu) |

The full skill catalogue and invocation rules live in [40-skills.md](40-skills.md).

## When to Use Which Execution Mode

| Situation                                          | Recommended path                                                     |
|----------------------------------------------------|----------------------------------------------------------------------|
| Greenfield feature, uncertain requirements         | `/superpowers:brainstorming` then `/superpowers:writing-plans` then `/superpowers:subagent-driven-development` |
| Greenfield feature, clear spec, want team pattern  | `/superpowers:brainstorming` then `/assemble-team`                   |
| Existing bug in a tracked issue                    | `/fix-issue` (escalate to `/superpowers:systematic-debugging` if stuck) |
| Existing unclear bug                               | `/superpowers:systematic-debugging` then `/superpowers:test-driven-development` for the regression test |
| Refactor an existing module                        | `/refactor-module` for simple cases; `/superpowers:brainstorming` + `/superpowers:writing-plans` for architectural ones |
| Mass changes across many files                     | `workflows/mass-refactor.sh`                                         |
| Parallel independent fixes                         | `workflows/batch-fix.sh`                                             |

The default path for new work is the full pipeline. Shortcuts exist for situations where
the ceremony would add more friction than value — a typo fix does not need a brainstorming
session.

## Escalation Paths

Work often starts on a short path and escalates when it turns out to be harder than it
looked. Escalation is not failure — it is a signal that early estimates of the work's shape
were optimistic.

- **`/fix-issue` → `/superpowers:systematic-debugging`.** When a tracked issue's described
  symptom does not match any obvious cause in the code, abandon the quick-fix attempt and
  switch to the 4-phase root cause investigation.
- **`/refactor-module` → `/superpowers:brainstorming` + `/superpowers:writing-plans`.** When
  the refactor goal turns out to require cross-module changes or affects public contracts,
  stop and plan the work before continuing.
- **`/superpowers:subagent-driven-development` → `/assemble-team`.** When a planned task
  turns out to span multiple disciplines (backend + frontend + docs), switch from sequential
  subagents to a parallel team.
- **Exploratory spike → `/superpowers:test-driven-development`.** When a quick prototype
  graduates to real code, switch to the strict TDD loop and retrofit any untested behavior.

## Session State Handoff

Across sessions, ClaudeMaxPower preserves state through two mechanisms:

- **`.estado.md`** is written by the `stop` hook at the end of each session and read by the
  `session-start` hook at the beginning of the next one. The session-start hook surfaces
  only the three most recent entries to keep the loaded context small; older entries remain
  in the file for reference.
- **Claude Code's own auto-memory** (under the user-level memory directory) is the canonical
  store for user, feedback, project, and reference memories. ClaudeMaxPower does not maintain
  a separate memory store and does not run any background consolidation process.
