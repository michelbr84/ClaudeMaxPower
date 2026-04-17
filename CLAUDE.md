# ClaudeMaxPower — Project Instructions

> This is the root CLAUDE.md. It applies to every session in this project.
> Subfolder CLAUDE.md files extend or override these rules for their specific context.

## Project Identity

ClaudeMaxPower is an open-source GitHub template that turns Claude Code into a **coordinated AI
engineering team**. It works in two modes:

1. **New Project Supercharge** — Install ClaudeMaxPower and it assembles an agent team
   (Architect + Implementer + Tester + Reviewer + Doc Writer) from day one.
2. **Existing Project Acceleration** — Add ClaudeMaxPower to a project in progress and it
   assembles a team tailored to your pending work (Analyst + parallel Implementers + Reviewer).

Every technique — hooks, skills, agents, teams, memory consolidation — is documented, tested,
and ready to adapt.

## Session Start Protocol

At the start of every session:
1. Check if `.estado.md` exists in the project root. If it does, read it to restore context.
2. Check if `.env` exists. If it doesn't, warn the user and suggest running `bash scripts/setup.sh`.
3. Identify which area of the project you're working in (hooks / skills / agents / examples / docs).
4. If the user's goal is ambiguous and involves any new feature, default to the pipeline:
   **brainstorm → spec → plan → execute → review → finish**.

## The Unified Pipeline (Superpowers + ClaudeMaxPower)

```
Idea
 ├─ /brainstorming        → docs/specs/YYYY-MM-DD-<topic>-design.md   (hard gate: user must approve)
 ├─ /writing-plans        → docs/plans/YYYY-MM-DD-<topic>-plan.md     (bite-sized tasks, 2-5 min each)
 ├─ /using-worktrees      → isolated branch workspace
 ├─ /subagent-dev         → fresh subagent per task + two-stage review (spec → quality)
 │    └─ /tdd-loop            (strict Red-Green-Refactor, iron law)
 │    └─ /systematic-debugging (when a bug is encountered: root cause before fix)
 └─ /finish-branch        → merge / PR / keep / discard + worktree cleanup
```

Alternate entry points:
- **Existing GitHub issue** → `/fix-issue` (escalates to `/systematic-debugging` if stuck)
- **Structured review** → `/review-pr`
- **Architectural refactor** → `/brainstorming` + `/writing-plans`
- **Simple refactor** → `/refactor-module`
- **Team pattern for large features** → `/assemble-team` (enforces brainstorming gate in new-project mode)
- **One-command bootstrap** → `/max-power` (installs, configures, presents menu)

## The Four Iron Laws

These are enforced by the skills above and should be respected in every session:

1. **No production code without a failing test first** (/tdd-loop)
2. **No implementation without an approved spec** (/brainstorming hard gate)
3. **No fixes without root cause investigation** (/systematic-debugging Phase 1)
4. **No merging with failing tests** (/finish-branch verification step)

## Core Coding Conventions

- **Languages**: Shell (bash), Python 3, Markdown. Match the language of the file being modified.
- **Shell scripts**: Use `set -euo pipefail`. Always quote variables. Use `local` in functions.
- **Python**: PEP 8. Type hints for public functions. pytest for tests. No global state.
- **Markdown**: ATX headings (`#`). 100-char line limit. Fenced code blocks with language tags.
- **Commit messages**: Conventional Commits format (`feat:`, `fix:`, `docs:`, `chore:`).

## Absolute Rules (Never Break These)

- NEVER run `rm -rf /` or any destructive command without explicit user confirmation.
- NEVER commit `.env` or any file containing real secrets or tokens.
- NEVER push to `main` or `master` branch directly. Always use a feature branch + PR.
- NEVER skip tests when they exist. If tests fail, fix the code, not the tests.
- NEVER mock the filesystem or database in tests when real implementations are available.

## Preferred Tool Patterns

- File search: Glob tool (not `find`)
- Content search: Grep tool (not `grep`)
- File reads: Read tool (not `cat`)
- File edits: Edit tool for targeted changes, Write tool only for new files or full rewrites
- Shell: Bash tool only for commands that require execution

## Skills Available

The following skills are defined in `skills/` and can be invoked with `/skill-name`.

**Pipeline skills (Superpowers methodology, MIT attributed):**

| Skill | Command | Purpose |
|-------|---------|---------|
| brainstorming | `/brainstorming` | Collaborative design → spec (hard gate before any implementation) |
| writing-plans | `/writing-plans` | Break an approved spec into bite-sized tasks |
| subagent-dev | `/subagent-dev` | Execute a plan with fresh subagent per task + two-stage review |
| systematic-debugging | `/systematic-debugging` | 4-phase root-cause debugging (reproduce → isolate → fix → verify) |
| finish-branch | `/finish-branch` | Complete work: merge / PR / keep / discard + worktree cleanup |
| using-worktrees | `/using-worktrees` | Create isolated git worktree with safety verification |
| tdd-loop | `/tdd-loop` | Strict Red-Green-Refactor with iron-law enforcement |
| tdd-loop-lite | `/tdd-loop-lite` | Simpler TDD loop (pre-integration version, kept for flexibility) |

**ClaudeMaxPower native skills:**

| Skill | Command | Purpose |
|-------|---------|---------|
| max-power | `/max-power` | One-command activation — install, configure, route to your goal |
| assemble-team | `/assemble-team` | Assemble an agent team (enforces brainstorming gate in new-project mode) |
| fix-issue | `/fix-issue` | Fix a GitHub issue end-to-end |
| review-pr | `/review-pr` | Full PR review workflow |
| refactor-module | `/refactor-module` | Safe module refactor with tests |
| pre-commit | `/pre-commit` | Intelligent pre-commit checks |
| generate-docs | `/generate-docs` | Auto-generate docs from code |

## Agents Available

Specialized agents are defined in `.claude/agents/`:
- `code-reviewer` — strict code review with project memory
- `security-auditor` — OWASP-based vulnerability scanning
- `doc-writer` — documentation generation with user memory
- `team-coordinator` — orchestrates agent teams with task dependencies

## Auto Dream (Memory Consolidation)

ClaudeMaxPower includes Auto Dream — a background process that consolidates memory files.
It runs automatically via the session-start hook when 24+ hours and 5+ sessions have passed
since the last consolidation. See `docs/auto-dream-guide.md` for details.

## Documentation References

- @docs/hooks-guide.md
- @docs/skills-guide.md
- @docs/agents-guide.md
- @docs/agent-teams-guide.md
- @docs/auto-dream-guide.md
- @docs/batch-workflows.md
- @docs/superpowers-integration.md
- @docs/bootstrap-prompt.md
- @ATTRIBUTION.md
