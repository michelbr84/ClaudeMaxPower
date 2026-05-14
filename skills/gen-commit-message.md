---
name: gen-commit-message
description: Use when user has staged changes and asks for a commit message, says "what should the commit message be", or types /gen-commit-message. Reads `git diff --staged` and proposes a Conventional Commits message (feat/fix/docs/refactor/test/chore).
arguments: []
allowed-tools:
  - Bash
  - Read
---

# Skill: gen-commit-message

Read the staged diff and propose a Conventional Commits message. Replaces the LLM-judgment
portion of the old `/pre-commit` skill (the deterministic checks now live in
`.claude/hooks/pre-commit-check.sh` and fire automatically before `git commit`).

## Workflow

### Step 1: Verify there are staged changes

```bash
git diff --staged --stat
```

If nothing is staged, tell the user and stop:

> Nothing is staged. Run `git add <files>` first, then re-invoke `/gen-commit-message`.

### Step 2: Read the staged diff

```bash
git diff --staged
```

Read the full diff. Identify:

- The dominant change type (feature, bugfix, docs, refactor, test, tooling).
- The scope (single module/package, or a sweep across many).
- The user-visible behavior change (or "none" for refactors and chores).

### Step 3: Propose a Conventional Commits message

Format: `<type>(<scope>): <subject>`

Type vocabulary (pick one):

- `feat` — new user-visible feature
- `fix` — bug fix
- `docs` — documentation only (no code change)
- `refactor` — code change with no behavior change
- `test` — adding or fixing tests
- `chore` — tooling, deps, CI, build config

Subject rules: imperative mood, lowercase, no trailing period, ≤ 70 characters.

Optional body: separated by a blank line, wraps at ~72 columns. Use it to explain *why* when
the *what* is non-obvious from the diff.

Example output:

```
fix(todo): resolve off-by-one error in delete_task

The bound check used `i < n` instead of `i <= n` when scanning the
deletion index, so the final task in any list was never removed.
```

### Step 4: Closing prompt (use / edit / regenerate)

Present three options and wait for the user's choice:

```
Use this message?
  1) Use as-is — I'll print the `git commit -m` command for you to copy
  2) Edit — tell me what to change
  3) Regenerate — propose a different message
```

If the user picks (1), output the exact command they should run:

```bash
git commit -m "<subject>" -m "<body, if any>"
```

Do NOT execute the commit yourself — let the user run it so the pre-commit-check hook fires
naturally.

**Feedback:** Did the proposed message match the change? Reply with a 1–10 rating or suggest
a faster path from where you started to where you ended.
