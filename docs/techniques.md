# Advanced Claude Code Techniques

This document describes the 14 techniques that inspired and shaped ClaudeMaxPower. Each technique solves a real productivity problem. Each one is implemented somewhere in this project — links show you where.

---

## Part 1: Official Best Practices

*Based on official Claude Code documentation and Anthropic's recommended patterns.*

### 1. Layered `CLAUDE.md` with Imports and Per-Folder Rules

**Problem it solves:** Claude understands your code but doesn't know your local conventions, test commands, architectural exceptions, or deployment rules. Without this, you waste time correcting the same behavior every session.

**How it works:** Claude Code reads `CLAUDE.md` at the start of every session and supports `@imports` for pulling in external docs without inflating the main file. You can place `CLAUDE.md` files at:
- `~/.claude/CLAUDE.md` — global preferences across all projects
- `./CLAUDE.md` — project-wide rules
- `./src/api/CLAUDE.md` — rules for a specific subsystem

The advanced technique: put only decision rules and critical commands at the top; push long detail into imported files or skills.

```markdown
# CLAUDE.md
See @README.md for project overview and @package.json for scripts.

## Workflow Rules
- Before finishing any backend task, run `pnpm --filter api test`
- In migrations: generate files only, never apply without asking
- For auth changes, consult @docs/auth-rules.md
```

**Implemented in ClaudeMaxPower:**
- [`CLAUDE.md`](../CLAUDE.md) — root project instructions with `@imports`
- [`examples/todo-app/CLAUDE.md`](../examples/todo-app/CLAUDE.md) — subfolder Python/pytest overrides
- [`examples/tdd-demo/CLAUDE.md`](../examples/tdd-demo/CLAUDE.md) — TDD-first mandate

---

### 2. Deterministic Hooks

**Problem it solves:** Prompts can be forgotten; hooks cannot. Good intentions ("always run tests after editing") need enforcement, not repetition.

**How it works:** Hooks fire automatically at key moments:
- `SessionStart` — prepare environment, load state, orient Claude
- `PreToolUse` — block dangerous commands, validate paths before execution
- `PostToolUse` (async) — run lint/tests after edits, without blocking the response
- `Stop` — prevent Claude from declaring "done" before real criteria are met

The result: quality gates that work in every session without prompting.

```bash
# Example: auto-run tests after every Python file edit
if [[ "$FILE" == *.py ]]; then
  python -m pytest tests/ -q --tb=short
fi
```

**Implemented in ClaudeMaxPower:**
- [`.claude/hooks/session-start.sh`](../.claude/hooks/session-start.sh)
- [`.claude/hooks/pre-tool-use.sh`](../.claude/hooks/pre-tool-use.sh) — blocks `rm -rf /`, force pushes, `DROP TABLE`
- [`.claude/hooks/post-tool-use.sh`](../.claude/hooks/post-tool-use.sh) — auto-runs pytest / npm test
- [`.claude/hooks/stop.sh`](../.claude/hooks/stop.sh) — saves session state to `.estado.md`
- [`.claude/settings.json`](../.claude/settings.json)

---

### 3. Skills as Reusable "Engineering Macros"

**Problem it solves:** Repeating the same multi-step workflows (fix issue, review PR, run deploy checklist) consumes context and requires re-explaining the same procedure every time.

**How it works:** Skills are `.md` files with YAML frontmatter that Claude reads as parameterized macros. Key frontmatter fields:
- `allowed-tools` — restrict Claude to only what the skill needs (principle of least privilege)
- `arguments` — typed, documented parameters
- `description` — Claude uses this to understand when to auto-invoke

```yaml
---
name: fix-issue
description: Fix a GitHub issue end-to-end using TDD
allowed-tools: Bash, Read, Edit, Glob, Grep
---
```

**Implemented in ClaudeMaxPower:**
- [`skills/fix-issue.md`](../skills/fix-issue.md)
- [`skills/review-pr.md`](../skills/review-pr.md)
- [`skills/refactor-module.md`](../skills/refactor-module.md)
- [`skills/tdd-loop.md`](../skills/tdd-loop.md)
- [`skills/pre-commit.md`](../skills/pre-commit.md)
- [`skills/generate-docs.md`](../skills/generate-docs.md)

---

### 4. Sub-Agents with Persistent Memory

**Problem it solves:** The main conversation gets polluted when Claude needs to explore, review, compare, or find edge cases. Mixing "writer" and "reviewer" roles in one context degrades output quality.

**How it works:** Sub-agents are separate Claude sessions with:
- Their own context (not sharing main conversation)
- `memory: project` — learns codebase-specific patterns across sessions
- `memory: user` — learns your style preferences over time
- Restricted tools — can't accidentally write or delete

The underused technique: explicitly ask agents to consult and update their memory at the end of each session. They improve over time.

```markdown
---
name: code-reviewer
memory: project
allowed-tools: Read, Glob, Grep
---
```

**Implemented in ClaudeMaxPower:**
- [`.claude/agents/code-reviewer.md`](../.claude/agents/code-reviewer.md) — project memory
- [`.claude/agents/security-auditor.md`](../.claude/agents/security-auditor.md) — project memory
- [`.claude/agents/doc-writer.md`](../.claude/agents/doc-writer.md) — user memory

---

### 5. MCP + CLI Tools as Real Claude Extensions

**Problem it solves:** Most productivity loss isn't in writing code — it's in switching between GitHub, Sentry, databases, logs, and docs. Without integration, you copy-paste context manually for every session.

**How it works:** Claude Code supports MCP (Model Context Protocol) for connecting to APIs, databases, and services. Combined with CLI tools (`gh`, `aws`, `sentry-cli`), Claude can execute complete workflows end-to-end:

> Read the issue → check Sentry errors → look at the DB → implement the fix → open a PR

All without leaving the session.

**Implemented in ClaudeMaxPower:**
- [`mcp/github-config.json`](../mcp/github-config.json)
- [`mcp/sentry-config.json`](../mcp/sentry-config.json)
- [`mcp/README.md`](../mcp/README.md)
- Skills use `gh` CLI throughout

---

### 6. Headless Batch Automation with `claude --print`

**Problem it solves:** Interactive sessions are too slow for bulk tasks: auditing many files, repetitive migrations, CI checks, structured report generation.

**How it works:** `claude --print` (or `claude -p`) runs Claude non-interactively:

```bash
claude --print "List all typing problems in this file" \
  --allowedTools "Read,Bash" \
  --output-format json
```

Use it in scripts to process many items with one Claude call each. Horizontally scalable.

```bash
for f in $(git diff --name-only | grep '\.ts$'); do
  claude --print "Review $f and return JSON with severity, summary, fix" \
    --output-format json
done
```

**Implemented in ClaudeMaxPower:**
- [`workflows/batch-fix.sh`](../workflows/batch-fix.sh)
- [`workflows/mass-refactor.sh`](../workflows/mass-refactor.sh)
- [`examples/batch-demo/run.sh`](../examples/batch-demo/run.sh)

---

### 7. Parallel Sessions with Git Worktrees (Writer/Reviewer)

**Problem it solves:** A single session mixes implementation, review, and experimentation — contaminating context and lowering review quality (you can't objectively review code you just wrote in the same session).

**How it works:** Git worktrees let multiple branches exist simultaneously as separate directories. Two Claude sessions work in isolation:

```bash
# Session 1 in worktree-a: implements the feature
# Session 2 in worktree-b: reviews the diff without bias
```

The Reviewer has never seen the implementation, so the review is genuinely independent. You can add a third session for testing.

**Implemented in ClaudeMaxPower:**
- [`workflows/parallel-review.sh`](../workflows/parallel-review.sh)
- [`docs/worktrees-parallel.md`](worktrees-parallel.md)

---

## Part 2: CLI-First Techniques

*Practical patterns that treat Claude as an autonomous local agent — not just a chat interface.*

### 8. Autonomous TDD Loop

**Problem it solves:** The tedious cycle of running tests, reading errors, opening files, fixing, saving, running again — repeated until green.

**How it works:** Claude has terminal access and can run this loop itself. Delegate the entire cycle:

> "Run `npm run test:ui`. For each failing test, analyze the corresponding component and test file, fix the component logic, save, and run again until all pass."

Claude reads stderr, navigates to source files, applies fixes, and re-runs — recursively, without you watching.

**Implemented in ClaudeMaxPower:**
- [`skills/tdd-loop.md`](../skills/tdd-loop.md) — max 10 iterations, reports progress each time
- [`examples/tdd-demo/`](../examples/tdd-demo/) — demo project for practicing this

---

### 9. Architecture Injection via `CLAUDE.md`

**Problem it solves:** Claude frequently forgets project-specific conventions (use CSS modules, not styled-components; never use `any`; always use parameterized queries) requiring constant micro-corrections.

**How it works:** `CLAUDE.md` is a versioned system prompt. Commit it to the repo. Every developer and every session gets the same rules automatically — without any prompting.

```markdown
## Code Rules
1. TypeScript strict mode. `any` is forbidden.
2. Styling: Tailwind utility classes only. No `.css` files.
3. React components: Arrow Functions with destructured props.
```

The rules travel with the code. New team members get them instantly.

**Implemented in ClaudeMaxPower:**
- [`CLAUDE.md`](../CLAUDE.md) — includes forbidden actions, preferred tools, session protocol

---

### 10. Direct Stack Trace Debugging

**Problem it solves:** Copying giant error logs from terminal to a chat interface loses local module context and import paths.

**How it works:** Claude compiles or runs the project directly, reads the stack trace output, navigates to the exact source file using the trace, understands the local context, and fixes the issue:

> "Run `tsc --noEmit`. For each type error, navigate to the `.ts` file, understand the expected interface in context, fix the typing, and repeat until the build passes clean."

No copy-paste. The full file system is available.

---

### 11. Batch Refactoring with Grep + Iteration

**Problem it solves:** Structural refactors (renaming a global hook, changing route structure) break dozens of files. Asking Claude to "update the project" without precision causes hallucinations.

**How it works:** Use Claude's bash access to first map the problem scope with `grep`/`rg`, then iterate surgically over only the affected files:

> "Use `rg 'useOldAuth'` to list all files importing this hook. Read each one and replace it with `useSession`. Remove orphaned imports. Verify TypeScript types are correct for each substitution."

Grep first, then fix — never guess the scope.

**Implemented in ClaudeMaxPower:**
- [`workflows/mass-refactor.sh`](../workflows/mass-refactor.sh) — grep + `claude --print` per file

---

### 12. Pre-Commit Agent

**Problem it solves:** Committing code that isn't linted, typed, or formatted correctly — failing CI or requiring a follow-up cleanup commit.

**How it works:** Before every commit, Claude acts as an intelligent linter. It inspects the staging area, applies architectural rules, fixes files if needed, and generates a conventional commit message:

> "Analyze `git diff --cached`. Check for Tailwind conflicts and TypeScript rule violations. Fix any linting issues in staged files. If everything is clean, generate a Conventional Commits message."

**Implemented in ClaudeMaxPower:**
- [`skills/pre-commit.md`](../skills/pre-commit.md) — secret scan, debug detection, linter, commit message

---

### 13. Database-to-UI Reverse Engineering

**Problem it solves:** Writing all frontend boilerplate (TypeScript types, fetch hooks, table components) every time a new entity is added to the database.

**How it works:** Claude has access to all local files. Point it at the schema, and it generates the entire frontend stack in the correct directories:

> "Read `schema.sql`, focusing on the `customers` table. Generate the TypeScript interface in `src/types/`, a custom fetch hook in `src/hooks/`, and a grid component with Tailwind in `src/components/`. Run Prettier on the generated files."

One prompt → complete feature scaffold.

---

### 14. Strategic Memory Offloading

**Problem it solves:** Long sessions exhaust the context window — making Claude lose track of earlier instructions and degrading output quality over time.

**How it works:** Before clearing context, make Claude write its "mental state" to disk. The next session reads this file to resume with clean context:

> "We're finishing the auth refactor but the session is getting heavy. Write a detailed summary of what we've implemented and what remains to `.estado_auth.md`. I'll use `/compact` then start fresh by reading that file."

The `stop.sh` hook in ClaudeMaxPower does this automatically at the end of every session.

**Implemented in ClaudeMaxPower:**
- [`.claude/hooks/stop.sh`](../.claude/hooks/stop.sh) — auto-saves session summary to `.estado.md`
- [`.claude/hooks/session-start.sh`](../.claude/hooks/session-start.sh) — reads `.estado.md` at session open

---

## Summary: Implementation Order

If you're starting from scratch, apply these in this order:

| # | Technique | Why First |
|---|-----------|-----------|
| 1 | Layered `CLAUDE.md` | Foundation — everything else builds on it |
| 2 | Hooks (`PreToolUse`, `PostToolUse`, `Stop`) | Safety net + quality gates |
| 3 | 2–3 Skills | Eliminate the most repeated manual workflows |
| 4 | One sub-agent with memory | Specialized review that improves over time |
| 5 | `claude --print` for batch tasks | Scale up what's already working |
| 6 | Git worktrees (Writer/Reviewer) | Quality boost for complex features |
| 7 | MCP integrations | Connect to the systems you use every day |

All 7 (and more) are already set up in ClaudeMaxPower. Clone, run `bash scripts/setup.sh`, and start with `/fix-issue`.
