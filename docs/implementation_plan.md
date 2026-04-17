# Integrate Superpowers into ClaudeMaxPower + One-Command Bootstrap

## Background

**ClaudeMaxPower** is your power-user toolkit for Claude Code — it provides hooks, skills, agents, team coordination, memory/Auto Dream, and batch workflows. It's structured around a "team assembly" metaphor with role-based agents (Architect, Implementer, Tester, Reviewer, Doc Writer).

**obra/superpowers** (157k ★) is an agentic skills framework and software development methodology. Its core pipeline is: brainstorm → spec → plan → subagent-driven development (with TDD and two-stage review) → finish branch. It's designed as a plugin system installable into Claude Code, Cursor, Codex, Gemini CLI, etc.

### Why Merge Them?

| ClaudeMaxPower has... | Superpowers adds... |
|---|---|
| Agent team assembly & coordination | Rigorous brainstorming → spec → plan pipeline |
| hooks (session-start, pre/post-tool, stop) | Subagent-driven development with two-stage review |
| Skills (fix-issue, review-pr, refactor, tdd-loop) | Strict RED-GREEN-REFACTOR TDD methodology |
| Auto Dream memory consolidation | Git worktrees for isolated development |
| Batch & parallel workflow scripts | Systematic debugging (4-phase root cause) |
| MCP integrations (GitHub, Sentry) | Visual brainstorming companion |
| `.estado.md` state tracking | Spec-driven planning with bite-sized tasks |

The result is **ClaudeMaxPower + Superpowers** — a toolkit where Claude:
1. **Brainstorms and specs** before writing any code (Superpowers)
2. **Assembles a specialized team** to execute the plan (ClaudeMaxPower)
3. **Uses subagent-driven development** with TDD and two-stage review (Superpowers)
4. **Persists memory** across sessions with Auto Dream (ClaudeMaxPower)
5. **Guards quality** with hooks, security audits, and batch automation (ClaudeMaxPower)

---

## User Review Required

> [!IMPORTANT]
> **Integration strategy:** We are NOT forking superpowers. We are importing and adapting their skill files into ClaudeMaxPower's `skills/` directory, crediting the source. This keeps ClaudeMaxPower self-contained and avoids a submodule dependency on a fast-moving 157k-star repo.

> [!IMPORTANT]
> **Bootstrap command:** You asked for a single command/prompt to "install and start working with ClaudeMaxPower at maximum capacity." The plan creates a `/max-power` skill that handles:
> 1. Cloning/copying ClaudeMaxPower files into the target project
> 2. Installing the Superpowers plugin (official marketplace or direct)
> 3. Running the setup script
> 4. Presenting the user with available capabilities
>
> **Plus** a copyable system prompt you can paste into any Claude session to bootstrap everything.

> [!WARNING]
> **Skill overlap:** ClaudeMaxPower already has `tdd-loop`. Superpowers' `test-driven-development` is far more rigorous (iron law, deletion rules, anti-rationalization tables). The plan **replaces** `tdd-loop.md` with an enhanced version that merges both approaches. If you want to keep the original tdd-loop as a separate "lite" option, let me know.

---

## Proposed Changes

### Component 1 — New Superpowers Skills (Import & Adapt)

Import the core Superpowers methodology skills into `skills/`, adapted to ClaudeMaxPower's format and naming conventions (adding `--- name/description/arguments ---` YAML frontmatter).

#### [NEW] [brainstorming.md](file:///g:/Projetos/ClaudeMaxPower/skills/brainstorming.md)
- Collaborative design refinement before any implementation
- Socratic questioning, one question at a time, multiple choice preferred
- Saves spec to `docs/specs/YYYY-MM-DD-<topic>-design.md`
- Hard gate: NO implementation until user approves spec
- Visual companion offer for UI-related projects
- Transitions to `writing-plans` skill after spec approval

#### [NEW] [writing-plans.md](file:///g:/Projetos/ClaudeMaxPower/skills/writing-plans.md)
- Breaks approved spec into bite-sized tasks (2-5 minutes each)
- Each task has exact file paths, complete code expectations, verification steps
- Creates plan file at `docs/plans/YYYY-MM-DD-<topic>-plan.md`
- Tasks are designed for subagent execution (isolated, independent)

#### [NEW] [subagent-dev.md](file:///g:/Projetos/ClaudeMaxPower/skills/subagent-dev.md)
- Dispatches fresh subagent per task from the plan
- Two-stage review: spec compliance first, then code quality
- Handles implementer status (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED)
- Model selection guidance (cheap for mechanical, capable for design)
- Includes prompt templates for implementer, spec reviewer, and quality reviewer

#### [NEW] [systematic-debugging.md](file:///g:/Projetos/ClaudeMaxPower/skills/systematic-debugging.md)
- 4-phase root cause process: reproduce → isolate → fix → verify
- Root-cause tracing technique
- Defense-in-depth approach
- Condition-based waiting (for timing-sensitive bugs)
- Never fix a bug without a failing test first

#### [NEW] [finish-branch.md](file:///g:/Projetos/ClaudeMaxPower/skills/finish-branch.md)
- Verifies all tests pass on the branch
- Presents options: merge, create PR, keep branch, discard
- Cleans up worktrees after merge

#### [NEW] [using-worktrees.md](file:///g:/Projetos/ClaudeMaxPower/skills/using-worktrees.md)
- Creates isolated workspace on new branch using `git worktree`
- Runs project setup in the worktree
- Verifies clean test baseline before starting work
- Integrates with existing `parallel-review.sh` workflow

---

### Component 2 — Enhanced Existing Skills

#### [MODIFY] [tdd-loop.md](file:///g:/Projetos/ClaudeMaxPower/skills/tdd-loop.md)
- **Replace** with enhanced version incorporating Superpowers' strict TDD:
  - Iron Law: NO production code without a failing test first
  - Mandatory RED verification (watch it fail)
  - Anti-rationalization table (12 common excuses with rebuttals)
  - Red flags that trigger "start over"
  - Testing anti-patterns reference
  - Delete-and-rewrite policy (no "keeping as reference")
- Preserves existing `--spec`, `--file`, `--test-file` arguments
- Adds iteration tracking and verification checklist

#### [MODIFY] [assemble-team.md](file:///g:/Projetos/ClaudeMaxPower/skills/assemble-team.md)
- Add a **step 0** that triggers `brainstorming` skill before assembling
- When in `new-project` mode, require spec approval before team spawn
- Add subagent-driven development as an execution strategy option
- Reference `writing-plans` for task breakdown

---

### Component 3 — The Bootstrap Command (`/max-power`)

#### [NEW] [max-power.md](file:///g:/Projetos/ClaudeMaxPower/skills/max-power.md)
The one-command activation skill. When invoked, it:

1. **Detects environment:** Is this a new project or existing? Is ClaudeMaxPower already installed?
2. **Installs ClaudeMaxPower** (if not present):
   - Copies `.claude/`, `skills/`, `scripts/`, `workflows/`, `CLAUDE.md` into the target project
   - Runs `bash scripts/setup.sh`
3. **Installs Superpowers plugin** (if Claude Code):
   - Runs `/plugin install superpowers@claude-plugins-official` (official marketplace)
   - Falls back to marketplace registration if official not available
4. **Activates full system:**
   - Reads project context (README, package.json, etc.)
   - Presents available skills as a menu
   - Asks user their immediate goal
   - Routes to appropriate skill (brainstorming for new features, fix-issue for bugs, etc.)
5. **Outputs a status dashboard** showing all active capabilities

---

### Component 4 — The Bootstrap Prompt (Copyable Text)

#### [NEW] [bootstrap-prompt.md](file:///g:/Projetos/ClaudeMaxPower/docs/bootstrap-prompt.md)
A ready-to-paste prompt the user inserts into any Claude session to bootstrap the full system. The prompt:

1. Instructs Claude to clone ClaudeMaxPower
2. Instructs Claude to install the Superpowers plugin
3. Instructs Claude to run setup
4. Activates the full skill pipeline
5. Tells Claude to behave with the full Superpowers methodology (brainstorm → spec → plan → subagent → TDD → review → finish)

This is the "copy-paste this into Claude and you're running at max power" artifact.

---

### Component 5 — Updated Configuration & Documentation

#### [MODIFY] [CLAUDE.md](file:///g:/Projetos/ClaudeMaxPower/CLAUDE.md)
- Add the imported Superpowers skills to the Skills Available table
- Add Superpowers methodology overview to Session Start Protocol
- Add reference to bootstrap prompt
- Add pipeline diagram: brainstorm → spec → plan → execute (SDD or team) → review → finish

#### [MODIFY] [README.md](file:///g:/Projetos/ClaudeMaxPower/README.md)
- Add "Superpowers Integration" section explaining the merged methodology
- Update the Quick Start to mention `/max-power`
- Update the Skills Reference table with new skills
- Add attribution to obra/superpowers
- Update architecture diagram

#### [NEW] [docs/superpowers-integration.md](file:///g:/Projetos/ClaudeMaxPower/docs/superpowers-integration.md)
- Detailed guide on how Superpowers methodology works within ClaudeMaxPower
- When to use brainstorming vs. jumping straight to assemble-team
- When to use subagent-dev vs. batch workflows vs. parallel-review
- Comparison table: ClaudeMaxPower workflow vs. pure Superpowers vs. merged

#### [MODIFY] [.claude/settings.json](file:///g:/Projetos/ClaudeMaxPower/.claude/settings.json)
- Add permissions for `git worktree` commands
- Add permissions for `claude` CLI plugin commands (if applicable)

---

## File Summary

| Action | File | Description |
|--------|------|-------------|
| NEW | `skills/brainstorming.md` | Collaborative ideation → spec skill |
| NEW | `skills/writing-plans.md` | Spec → implementation plan skill |
| NEW | `skills/subagent-dev.md` | Subagent-driven development skill |
| NEW | `skills/systematic-debugging.md` | 4-phase root cause debugging |
| NEW | `skills/finish-branch.md` | Branch completion workflow |
| NEW | `skills/using-worktrees.md` | Git worktree isolation |
| NEW | `skills/max-power.md` | **One-command bootstrap** |
| NEW | `docs/bootstrap-prompt.md` | **Copy-paste activation prompt** |
| NEW | `docs/superpowers-integration.md` | Integration guide |
| MODIFY | `skills/tdd-loop.md` | Enhanced with strict TDD methodology |
| MODIFY | `skills/assemble-team.md` | Add brainstorming gate + SDD option |
| MODIFY | `CLAUDE.md` | Updated skills table + pipeline |
| MODIFY | `README.md` | Updated docs + attribution |
| MODIFY | `.claude/settings.json` | New permissions |

---

## Open Questions

> [!IMPORTANT]
> **1. Superpowers plugin installation:** Should `/max-power` attempt to install the Superpowers plugin via Claude's plugin marketplace (`/plugin install superpowers@claude-plugins-official`), or should we fully inline all Superpowers skills into ClaudeMaxPower (making the plugin unnecessary)? The current plan does BOTH — inlines the skills AND offers plugin install. This gives maximum resilience but creates potential duplication.

> [!IMPORTANT]
> **2. TDD replacement vs. coexistence:** Should the enhanced TDD replace `tdd-loop.md` entirely, or should we keep the original as `tdd-loop-lite.md` for simpler use cases where the full Superpowers TDD rigor is overkill?

> [!IMPORTANT]
> **3. Attribution model:** How do you want to credit obra/superpowers? Options:
> - A) MIT license notice + link in each imported skill file header
> - B) A single `ATTRIBUTION.md` in the repo root
> - C) Both A and B

> [!IMPORTANT]
> **4. Bootstrap prompt target:** Should the bootstrap prompt in `docs/bootstrap-prompt.md` be designed for Claude Code specifically, or should it also work in Cursor, Codex, and other agents?

---

## Verification Plan

### Automated Tests
- Run `bash scripts/verify.sh` after all changes to ensure the project structure is valid
- Verify all new skill files have valid YAML frontmatter
- Run `shellcheck` on any modified shell scripts
- Test `/max-power` skill by simulating it in a fresh Claude Code session

### Manual Verification
- Open Claude Code in a fresh directory, paste the bootstrap prompt, and verify it:
  1. Clones ClaudeMaxPower
  2. Runs setup
  3. Presents the skills menu
  4. Successfully runs brainstorming + writing-plans flow on a test idea
- Verify the assemble-team → brainstorming gate works correctly
- Test the enhanced TDD loop with a simple Python function
