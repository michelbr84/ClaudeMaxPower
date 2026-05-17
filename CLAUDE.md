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

The methodology skills (brainstorming, plans, TDD, debugging, worktrees, finish) live
upstream in the Superpowers plugin. Install with
`/plugin install superpowers@claude-plugins-official` and invoke them with the
`/superpowers:*` namespace. ClaudeMaxPower keeps a thin `/superpowers-redirect` skill that
catches the old slash commands and points users to the canonical replacements.

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

Alternate entry points (native ClaudeMaxPower skills):
- **Existing GitHub issue** → `/fix-issue` (escalates to `/superpowers:systematic-debugging` if stuck)
- **Structured review** → `/review-pr`
- **Architectural refactor** → `/superpowers:brainstorming` + `/superpowers:writing-plans`
- **Simple refactor** → `/refactor-module`
- **Team pattern for large features** → `/assemble-team` (enforces brainstorming gate in new-project mode)
- **Conventional Commits message** → `/gen-commit-message` (the deterministic pre-commit checks now run automatically via `.claude/hooks/pre-commit-check.sh`)
- **One-command bootstrap** → `/max-power` (installs, configures, presents menu)

## The Four Iron Laws

These are enforced by the skills/hooks above and should be respected in every session:

1. **No production code without a failing test first** (`/superpowers:test-driven-development`)
2. **No implementation without an approved spec** (`/superpowers:brainstorming` hard gate)
3. **No fixes without root cause investigation** (`/superpowers:systematic-debugging` Phase 1)
4. **No merging with failing tests** (`/superpowers:finishing-a-development-branch` verification step)

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

The following native skills are defined in `skills/` and can be invoked with `/skill-name`.
The methodology skills (brainstorming, plans, TDD, etc.) live upstream in the Superpowers
plugin — install with `/plugin install superpowers@claude-plugins-official`.

**ClaudeMaxPower native skills (8):**

| Skill | Command | Purpose |
|-------|---------|---------|
| max-power | `/max-power` | One-command activation — install, configure, route to your goal |
| assemble-team | `/assemble-team` | Assemble an agent team (enforces brainstorming gate in new-project mode) |
| fix-issue | `/fix-issue` | Fix a GitHub issue end-to-end |
| review-pr | `/review-pr` | Full PR review workflow |
| refactor-module | `/refactor-module` | Safe module refactor with tests |
| generate-docs | `/generate-docs` | Auto-generate docs from code |
| gen-commit-message | `/gen-commit-message` | Read staged diff, propose Conventional Commits message |
| superpowers-redirect | `/superpowers-redirect` | Catches old `/brainstorming`-style commands and routes to canonical `/superpowers:*` |

Reference content for the larger skills lives in `skills/references/` (progressive
disclosure — Claude reads these on demand, not on every session start).

The deterministic pre-commit checks (secret scan, debug-statement scan, large-file warning,
linter) now run automatically via `.claude/hooks/pre-commit-check.sh` — no skill invocation
needed before `git commit`.

## Agents Available

Specialized agents are defined in `.claude/agents/`:
- `code-reviewer` — strict code review with project memory
- `security-auditor` — OWASP-based vulnerability scanning
- `doc-writer` — documentation generation with user memory
- `team-coordinator` — orchestrates agent teams with task dependencies

## Documentation References

- @docs/hooks-guide.md
- @docs/skills-guide.md
- @docs/agents-guide.md
- @docs/agent-teams-guide.md
- @docs/batch-workflows.md
- @docs/superpowers-integration.md
- @ATTRIBUTION.md
