# 50 — Tools and Coding Conventions

Preferred tool patterns for Claude and core coding conventions per language.

## Preferred Tool Patterns

Use the dedicated tool, not the shell command:

- **File search** — `Glob` tool (not `find`)
- **Content search** — `Grep` tool (not `grep`)
- **File reads** — `Read` tool (not `cat`)
- **File edits** — `Edit` for targeted changes, `Write` only for new files or full rewrites
- **Shell** — `Bash` only for commands that require execution

## Core Coding Conventions

- **Languages** — Shell (bash), Python 3, Markdown. Match the language of the file being
  modified.
- **Shell scripts** — Use `set -euo pipefail`. Always quote variables. Use `local` in
  functions.
- **Python** — PEP 8. Type hints for public functions. `pytest` for tests. No global state.
- **Markdown** — ATX headings (`#`). 100-char line limit. Fenced code blocks with language
  tags.
- **Commit messages** — Conventional Commits format. See
  [30-git-github-ci.md](30-git-github-ci.md) for the canonical commit policy.

## Test-Mocking Policy

The "do not mock the filesystem or database when real implementations are available" rule
lives in [10-iron-laws.md](10-iron-laws.md) under "Test Discipline" — it is an iron law, not
a coding convention.
