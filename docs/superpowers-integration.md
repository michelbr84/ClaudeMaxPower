# Superpowers Integration

How ClaudeMaxPower incorporates the obra/superpowers methodology into a unified, coordinated
engineering pipeline.

## 1. Introduction

[Superpowers](https://github.com/obra/superpowers) is an open-source project by Jesse Vincent
and contributors that codifies a rigorous software-engineering methodology for Claude Code. It
provides a set of skills (brainstorming, planning, TDD, subagent-driven development, systematic
debugging, worktree workflows, and branch finishing) that collectively enforce a disciplined
approach to building software with an AI collaborator. With over 157k stars on GitHub at the
time of this writing, it has become a reference point for structured Claude workflows.

ClaudeMaxPower is a GitHub template that turns Claude Code into a coordinated AI engineering
team. It ships with hooks (session-start, pre-tool-use, post-tool-use, stop), a skill library
(`/fix-issue`, `/review-pr`, `/refactor-module`, `/pre-commit`, `/generate-docs`), specialized
agents (`code-reviewer`, `security-auditor`, `doc-writer`, `team-coordinator`), Auto Dream
memory consolidation, and Agent Teams (`/assemble-team`) with two operating modes:
new-project and existing-project.

The two projects merge naturally. Superpowers contributes a methodology — how work flows from
idea to merged branch, with gates at each stage. ClaudeMaxPower contributes infrastructure —
hooks, memory consolidation, team orchestration, and batch workflows. Integrating them gives
a single template that enforces rigorous practice while automating the mechanical work around it.

The integration approach is to adapt and inline the relevant Superpowers skills directly into
the ClaudeMaxPower repository. This keeps the template self-contained (no submodules, no
external fetches during setup) while attributing the source. Each adapted skill carries an
attribution header, and `ATTRIBUTION.md` in the repository root is the single source of truth
for licensing.

## 2. The Unified Pipeline

The combined pipeline looks like this:

```
Idea
  |
  v
/brainstorming  ---------->  spec
  |                            |
  |                            v
  |                       /writing-plans  ---------->  plan
  |                                                     |
  |                                                     v
  |                                        +------------+------------+
  |                                        |                         |
  |                                        v                         v
  |                               /subagent-dev              /assemble-team
  |                               (with /tdd-loop             (parallel agents,
  |                                and /using-worktrees)       team review)
  |                                        |                         |
  |                                        +------------+------------+
  |                                                     |
  |                                                     v
  |                                             /finish-branch
  |
  |  (existing project entry points bypass brainstorming)
  |
  +-->  /fix-issue                     (tracked bug)
  +-->  /systematic-debugging          (unknown bug)
  +-->  /refactor-module               (small refactor)
  +-->  workflows/mass-refactor.sh     (repo-wide change)
  +-->  workflows/batch-fix.sh         (independent issues, headless)
```

Each step:

- **`/brainstorming`** — Collaborative design conversation that produces an approved spec.
  This is a hard gate: no implementation skill should run without a spec when the work is
  non-trivial.
- **`/writing-plans`** — Turns an approved spec into a bite-sized task plan, with each task
  sized for a single focused session.
- **`/subagent-dev`** — Spawns a fresh subagent for each task, runs strict TDD, and enforces
  two-stage review (self-review then independent review) before the task is marked complete.
- **`/tdd-loop`** — Strict test-driven development. Red, green, refactor. No production code
  without a failing test first. Used inside `/subagent-dev` and callable directly.
- **`/using-worktrees`** — Sets up an isolated git worktree so subagents and agent teams can
  edit files without conflicting with the main working directory.
- **`/assemble-team`** — Alternate execution mode. Spawns a small team of specialized agents
  (Architect, Implementer, Tester, Reviewer, Doc Writer) that work in parallel on a shared
  task list.
- **`/finish-branch`** — Decides what happens at the end: merge, open a PR, keep the branch
  open, or discard. Verifies tests pass before anything lands.
- **`/fix-issue`**, **`/systematic-debugging`** — Entry points for existing projects with
  tracked bugs or unexplained misbehavior.

## 3. When to Use Which Execution Mode

| Situation                                          | Recommended path                                                     |
|----------------------------------------------------|----------------------------------------------------------------------|
| Greenfield feature, uncertain requirements         | `/brainstorming` then `/writing-plans` then `/subagent-dev`          |
| Greenfield feature, clear spec, want team pattern  | `/brainstorming` then `/assemble-team`                               |
| Existing bug in a tracked issue                    | `/fix-issue` (escalate to `/systematic-debugging` if stuck)          |
| Existing unclear bug                               | `/systematic-debugging` then `/tdd-loop` for the regression test     |
| Refactor an existing module                        | `/refactor-module` for simple cases; `/brainstorming` + `/writing-plans` for architectural ones |
| Mass changes across many files                     | `workflows/mass-refactor.sh`                                         |
| Parallel independent fixes                         | `workflows/batch-fix.sh`                                             |

The default path for new work is the full pipeline. Shortcuts exist for situations where the
ceremony would add more friction than value — a typo fix does not need a brainstorming session.

### Escalation paths

Work often starts on a short path and escalates when it turns out to be harder than it
looked. The common escalation patterns:

- **`/fix-issue` escalates to `/systematic-debugging`.** When a tracked issue's described
  symptom does not match any obvious cause in the code, abandon the quick-fix attempt and
  switch to the 4-phase root cause investigation.
- **`/refactor-module` escalates to `/brainstorming` + `/writing-plans`.** When the refactor
  goal turns out to require cross-module changes or affects public contracts, stop and plan
  the work before continuing.
- **`/subagent-dev` escalates to `/assemble-team`.** When a planned task turns out to span
  multiple disciplines (backend + frontend + docs), switch from sequential subagents to a
  parallel team.
- **`/tdd-loop-lite` escalates to `/tdd-loop`.** When a quick prototype graduates to real
  code, switch to the strict loop and retrofit any untested behavior.

Escalation is not failure. It is a signal that early estimates of the work's shape were
optimistic, and the pipeline is designed to absorb that gracefully.

## 4. `/subagent-dev` vs `/assemble-team` vs Workflow Scripts

All three approaches exist because each optimizes for a different axis. Pick based on the
shape of the work.

| Approach                        | Isolation                  | Parallel  | Reviews              | Context cost | Best for                                      |
|---------------------------------|----------------------------|-----------|----------------------|--------------|-----------------------------------------------|
| `/subagent-dev`                 | worktree + fresh per task  | sequential| 2-stage per task     | Medium       | Independent tasks from an approved plan       |
| `/assemble-team`                | optional worktree          | parallel  | team review          | High         | Features requiring multiple specializations   |
| `workflows/parallel-review.sh`  | worktree                   | 2 sessions| post-hoc review      | Medium       | Writer/reviewer pattern on a single feature   |
| `workflows/batch-fix.sh`        | none (headless)            | serial    | none                 | Low          | Independent issues processed in bulk          |

`/subagent-dev` gives each task a clean context window — the subagent sees only its task and
the code it needs, not the history of every prior task. This trades parallelism for focus and
is the right choice when tasks are sequential by nature.

`/assemble-team` trades context cost for parallelism. Specialized agents work at the same
time, each with focused responsibilities. It shines when the feature spans multiple
disciplines (architecture, implementation, tests, docs) and those can proceed concurrently.

Workflow scripts (`parallel-review.sh`, `batch-fix.sh`, `mass-refactor.sh`) run Claude in
headless mode (`claude --print`). They are the right choice for CI-friendly, repeatable,
large-batch work where interactive refinement is not needed.

## 5. `/brainstorming` vs Jumping to `/assemble-team`

`/brainstorming` exists to resolve ambiguity before code is written. Use it when:

- Requirements are unclear or under-specified.
- Multiple reasonable approaches exist and the trade-offs need discussion.
- UI/UX considerations matter and the shape of the output is not yet fixed.
- Architecture decisions are involved (database schema, module boundaries, API contracts).

Jump directly to `/assemble-team` when:

- A spec already exists and is precise enough to implement from.
- Requirements were produced by a stakeholder and are not up for negotiation.
- The team structure you want (Architect + Implementer + Tester + Reviewer + Doc Writer) is
  already the right shape for the work.

For `/assemble-team --mode new-project`, the brainstorming gate is now enforced: a spec must
exist before the team is assembled. If no spec is present, `/assemble-team` will direct you
to `/brainstorming` first. `--mode existing-project` does not enforce the gate, because the
existing codebase itself serves as the specification of how things currently behave.

## 6. The Iron Laws Merged

Four non-negotiable rules that apply across the unified pipeline:

1. **No production code without a failing test first.** Enforced by `/tdd-loop`. A test must
   be written, observed to fail for the right reason, and only then is implementation code
   allowed. The "for the right reason" clause matters — a test that fails because of a typo
   is not a red test.
2. **No implementation without an approved spec.** Enforced by the `/brainstorming` gate.
   Non-trivial work requires a spec that names the problem, the chosen approach, and the
   success criteria. Trivial work (one-line fixes, typos) is exempt.
3. **No fixes without root cause investigation.** Enforced by `/systematic-debugging` Phase 1.
   Symptoms are not causes. A fix that makes the symptom go away without explaining why the
   symptom appeared is provisional at best.
4. **No merging with failing tests.** Enforced by `/finish-branch` Step 1 (verify). The test
   suite runs green before merge, PR, or any branch-finalizing action. If tests are failing,
   the branch is not finished.

These laws are cumulative. A change that passes tests (law 4) but skipped the spec (law 2) is
still a violation. A change with a spec and passing tests but no root-cause analysis (law 3)
is still a violation when it touches bug territory.

### Exceptions and their limits

There are legitimate exceptions to each law, but they are narrow:

- **Law 1 exception:** Exploratory spikes that will be deleted before merging. Use
  `/tdd-loop-lite` or just a scratch branch. The moment the spike becomes real code, the
  law applies retroactively — tests come before further production code.
- **Law 2 exception:** Trivial changes (typos, obvious one-liners, formatting) do not need a
  spec. A change is "trivial" when a reviewer would not ask "why?" about it.
- **Law 3 exception:** Known flakes with documented workarounds can be patched without deep
  root-cause investigation if the patch itself is well-isolated. But the underlying cause
  stays on the backlog.
- **Law 4 exception:** None. Failing tests block the merge. If a test is known-broken and
  unrelated, it must be marked as skipped with a tracking issue, not ignored.

These exceptions exist so the methodology does not become theater. If you find yourself
using them on every change, the shape of the work has shifted and the pipeline should be
reconsidered.

## 7. Memory Integration

Superpowers methodology interacts with ClaudeMaxPower's Auto Dream memory consolidation in
predictable ways:

- **Brainstorming decisions become project memories.** When a `/brainstorming` session lands
  on a significant design decision ("we use JWT for auth, not sessions"), the decision is
  recorded as a project-scoped memory. Auto Dream keeps these consolidated and deduplicated.
- **Post-review feedback becomes feedback memories.** When `/subagent-dev`'s two-stage review
  produces actionable feedback (style preferences, naming conventions, missing test patterns),
  that feedback is captured for reuse in later sessions.
- **Spec and plan file paths become reference memories.** The memory index tracks where the
  current spec and plan live, so future sessions can resume without re-asking.
- **Auto Dream prunes stale spec references.** Specs from archived or merged branches become
  noise in memory. Auto Dream's staleness check flags them. Files older than 30 days or
  references to branches that no longer exist are candidates for removal.

Memory consolidation runs at session start when both conditions are met: 24+ hours since the
last dream, and 5+ sessions since the last dream. See `docs/auto-dream-guide.md` for details.

## 8. Hook Interactions

ClaudeMaxPower's hooks continue to work transparently when Superpowers skills run. Each hook
plays a specific role in the unified pipeline:

- **`pre-tool-use.sh`** — Logs every bash command to `.claude/audit.log` with a timestamp and
  blocks dangerous patterns. This works transparently for `/subagent-dev` subagents — the
  subagent's commands are logged alongside the main session's. Blocked patterns (fork bombs,
  `rm -rf /`, force-pushes to main) are blocked no matter which skill triggered them.
- **`post-tool-use.sh`** — Automatically runs tests after `Edit` or `Write` tool calls. This
  reinforces TDD during `/subagent-dev`: every code change immediately triggers the test
  suite, and the subagent learns of breakage before moving to the next step.
- **`session-start.sh`** — Reads `.estado.md` to restore context from the previous session.
  When a `/brainstorming` session ends mid-spec, the pending spec file path is captured in
  `.estado.md`, and the next session picks up where the previous left off.
- **`stop.sh`** — Saves a session summary to `.estado.md`. Brainstorming decisions, approved
  spec references, and partial plan progress are preserved across restarts.

Hooks and skills are orthogonal layers. Hooks enforce guardrails on every action; skills
organize multi-step workflows. Together they form the infrastructure on which Superpowers
methodology runs.

## 9. Pure Superpowers vs Pure ClaudeMaxPower vs Merged

| Dimension                 | Pure Superpowers        | Pure ClaudeMaxPower       | Merged (this repo)                    |
|---------------------------|-------------------------|---------------------------|---------------------------------------|
| Spec gate                 | Yes (`/brainstorming`)  | No                        | Yes, enforced in new-project mode     |
| TDD rigor                 | Strict (iron law)       | Optional (`/tdd-loop-lite`)| Strict (`/tdd-loop`) + lite available|
| Agent teams               | No                      | Yes (`/assemble-team`)    | Yes, with brainstorming gate          |
| Memory consolidation      | No                      | Yes (Auto Dream)          | Yes, Superpowers-aware                |
| Hooks (session/pre/post/stop) | No                  | Yes                       | Yes                                   |
| Worktrees                 | Yes (`/using-worktrees`)| Partial (`parallel-review.sh`)| Yes (`/using-worktrees` + scripts)|
| Two-stage review          | Yes (`/subagent-dev`)   | No                        | Yes                                   |
| Systematic debugging      | Yes (4-phase)           | No                        | Yes                                   |
| Branch finishing workflow | Yes (`/finish-branch`)  | No                        | Yes                                   |
| Batch / headless workflows| No                      | Yes (`workflows/*.sh`)    | Yes                                   |
| Specialized sub-agents    | No                      | Yes (reviewer, auditor)   | Yes                                   |
| MCP integrations          | Community-driven        | Not built-in              | Not built-in (user configurable)      |
| Bootstrap command         | No                      | `/max-power`              | `/max-power`                          |

The merged template is strictly more capable than either parent. Nothing was removed; the
only behavioral change is that `/tdd-loop` is now strict by default, and the original lighter
loop is preserved as `/tdd-loop-lite`.

## 10. Migration Guide

If you were using ClaudeMaxPower before this integration, here is what to expect:

- **Existing skills are unchanged.** `/fix-issue`, `/review-pr`, `/refactor-module`,
  `/pre-commit`, `/generate-docs`, and `/assemble-team` behave as before, with one exception
  noted below.
- **`/tdd-loop` is now strict.** It enforces the iron law: no production code without a
  failing test first. The earlier, more permissive loop is preserved as `/tdd-loop-lite` for
  cases where you want the old behavior (prototyping, exploratory work, notebooks).
- **`/assemble-team` enforces a brainstorming gate in new-project mode.** If you invoke
  `/assemble-team --mode new-project` without an approved spec, the skill will direct you to
  `/brainstorming` first. Existing-project mode is unchanged.
- **New skills are additive.** `/brainstorming`, `/writing-plans`, `/subagent-dev`,
  `/systematic-debugging`, `/finish-branch`, and `/using-worktrees` are all new and do not
  interfere with existing workflows.
- **Hooks, agents, Auto Dream, and workflow scripts are unchanged.** Your existing
  `.claude/settings.json`, `.claude/agents/`, and `workflows/` remain compatible.

No manual migration steps are required. Pull the new version of the template and existing
work continues to function.

## 11. Attribution and License

Superpowers is MIT-licensed. The adapted skill files in this repository carry an attribution
header that names the upstream skill and its license. `ATTRIBUTION.md` at the repository root
is the single source of truth for third-party content and licensing — consult it when in
doubt. ClaudeMaxPower itself is also MIT-licensed, and any derivative work that keeps the
adapted skills intact inherits the attribution requirement automatically.

## 12. References

- obra/superpowers — [https://github.com/obra/superpowers](https://github.com/obra/superpowers)
- ClaudeMaxPower — [https://github.com/michelbr84/ClaudeMaxPower](https://github.com/michelbr84/ClaudeMaxPower)
- Bootstrap prompt — `docs/bootstrap-prompt.md`
- Hooks guide — `docs/hooks-guide.md`
- Skills guide — `docs/skills-guide.md`
- Agents guide — `docs/agents-guide.md`
- Agent Teams guide — `docs/agent-teams-guide.md`
- Auto Dream guide — `docs/auto-dream-guide.md`
- Batch workflows — `docs/batch-workflows.md`
- Individual skill files in `skills/`
- Attribution and license — `ATTRIBUTION.md`
