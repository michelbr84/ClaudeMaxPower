# ClaudeMaxPower — Project Instructions

> This is the root CLAUDE.md. It applies to every session in this project.
> Subfolder CLAUDE.md files extend or override these rules for their specific context.

## Project Identity

ClaudeMaxPower is an open-source GitHub template demonstrating advanced Claude Code workflows.
The goal is to show how Claude can be used as a **production-grade AI coding assistant** — not just
a chat tool. Every technique here is documented, tested, and ready to adapt.

## Session Start Protocol

At the start of every session:
1. Check if `.estado.md` exists in the project root. If it does, read it to restore context.
2. Check if `.env` exists. If it doesn't, warn the user and suggest running `bash scripts/setup.sh`.
3. Identify which area of the project you're working in (hooks / skills / agents / examples / docs).

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

The following skills are defined in `skills/` and can be invoked with `/skill-name`:

| Skill | Command | Purpose |
|-------|---------|---------|
| fix-issue | `/fix-issue` | Fix a GitHub issue end-to-end |
| review-pr | `/review-pr` | Full PR review workflow |
| refactor-module | `/refactor-module` | Safe module refactor with tests |
| tdd-loop | `/tdd-loop` | Autonomous TDD loop until green |
| pre-commit | `/pre-commit` | Intelligent pre-commit checks |
| generate-docs | `/generate-docs` | Auto-generate docs from code |

## Agents Available

Specialized agents are defined in `.claude/agents/`:
- `code-reviewer` — strict code review with project memory
- `security-auditor` — OWASP-based vulnerability scanning
- `doc-writer` — documentation generation with user memory

## Documentation References

- @docs/hooks-guide.md
- @docs/skills-guide.md
- @docs/agents-guide.md
- @docs/batch-workflows.md
