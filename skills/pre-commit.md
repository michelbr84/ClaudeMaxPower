---
name: pre-commit
description: Intelligent pre-commit check — inspects staged changes for secrets, style issues, debug statements, and generates a conventional commit message.
arguments: []
allowed-tools:
  - Bash
  - Read
  - Grep
---

# Skill: pre-commit

Run this before every commit. Catches issues and generates a commit message.

## Workflow

### Step 1: Inspect the staged changes
```bash
git diff --staged --stat
git diff --staged
```

If nothing is staged, tell the user and stop.

### Step 2: Secret / credential leak detection
Scan staged content for patterns that suggest secrets:
```bash
git diff --staged | grep -iE \
  "(api_key|api-key|secret|password|passwd|token|private_key|credentials)" \
  | grep -v "example\|placeholder\|your_token\|# "
```

If any matches found: **STOP and warn the user.** Do not continue until secrets are removed.

### Step 3: Debug statement detection
Look for common debugging artifacts that shouldn't be committed:
```bash
git diff --staged | grep -E \
  "^\+.*(console\.log|print\(|debugger|pdb\.set_trace|breakpoint\(\)|TODO: REMOVE|FIXME: REMOVE)"
```

Report any found. These are warnings (not blockers), but the user should confirm they're intentional.

### Step 4: Large file check
```bash
git diff --staged --name-only | while read f; do
  if [ -f "$f" ]; then
    SIZE=$(wc -c < "$f")
    if [ "$SIZE" -gt 1048576 ]; then  # 1MB
      echo "LARGE FILE: $f ($SIZE bytes)"
    fi
  fi
done
```

Warn if any staged file exceeds 1MB.

### Step 5: Run linter on staged files
For Python files:
```bash
STAGED_PY=$(git diff --staged --name-only | grep '\.py$')
if [ -n "$STAGED_PY" ]; then
  echo "$STAGED_PY" | xargs flake8 --max-line-length=100 2>&1 || true
fi
```

For JavaScript/TypeScript:
```bash
STAGED_JS=$(git diff --staged --name-only | grep -E '\.(js|ts|jsx|tsx)$')
if [ -n "$STAGED_JS" ]; then
  echo "$STAGED_JS" | xargs npx eslint 2>&1 || true
fi
```

### Step 6: Generate commit message
Based on the staged diff, generate a [Conventional Commits](https://www.conventionalcommits.org/) message:

Format: `<type>(<scope>): <subject>`

Types:
- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `refactor` — code change with no behavior change
- `test` — adding or fixing tests
- `chore` — tooling, deps, CI

Example: `fix(todo): resolve off-by-one error in delete_task`

### Step 7: Final report

Present a summary:

```
## Pre-commit Report

### Staged Files
<list of staged files>

### Checks
- Secrets:        CLEAN | ⚠ FOUND (see above)
- Debug statements: CLEAN | ⚠ FOUND (see above)
- Large files:    CLEAN | ⚠ FOUND (see above)
- Linter:         PASS  | ✗ ISSUES (see above)

### Suggested Commit Message
<generated message>

### Verdict
SAFE TO COMMIT | REVIEW NEEDED
```

User decides whether to proceed with `git commit` or address the warnings first.
