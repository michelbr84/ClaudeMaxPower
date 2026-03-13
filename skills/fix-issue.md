---
name: fix-issue
description: Fix a GitHub issue end-to-end — reads the issue, reproduces the bug with a test, fixes the code, and opens a PR.
arguments:
  - name: issue
    description: GitHub issue number
    required: true
  - name: repo
    description: "Repository in owner/repo format (default: $DEFAULT_REPO from .env)"
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

# Skill: fix-issue

Fix a GitHub issue from start to finish, following TDD principles.

## Arguments

- `--issue <number>` — GitHub issue number to fix (required)
- `--repo <owner/repo>` — target repository (optional, defaults to `$DEFAULT_REPO` from `.env`)

## Workflow

### Step 1: Load environment
Load `.env` if it exists:
```bash
[ -f .env ] && export $(grep -v '^#' .env | xargs)
REPO="${REPO:-$DEFAULT_REPO}"
```

### Step 2: Read the issue
```bash
gh issue view $ISSUE --repo $REPO
```
Read the full issue body, comments, and labels. Understand:
- What the expected behavior is
- What the actual (broken) behavior is
- Any reproduction steps provided

### Step 3: Identify affected code
Use Grep and Glob to locate files related to the issue. Look for:
- Function names mentioned in the issue
- File paths referenced in the error
- Related test files

### Step 4: Write a failing test (TDD first)
Before touching any implementation:
1. Find the relevant test file (or create one if none exists)
2. Write a test that fails with the current broken behavior
3. Run the tests and confirm the new test is RED:
```bash
python -m pytest tests/ -v --tb=short -k "test_<relevant_name>"
```

### Step 5: Fix the bug
Now read the implementation file and apply the minimal fix that makes the failing test pass.
Do not refactor unrelated code. Do not change existing tests.

### Step 6: Verify all tests are green
```bash
python -m pytest tests/ -v --tb=short
```
If any tests fail (including pre-existing ones), fix them before proceeding.

### Step 7: Create a feature branch and PR
```bash
git checkout -b fix/issue-$ISSUE
git add -p  # stage only relevant changes
git commit -m "fix: resolve issue #$ISSUE — <short description>

Closes #$ISSUE"
git push origin fix/issue-$ISSUE
gh pr create \
  --repo $REPO \
  --title "fix: <short description> (closes #$ISSUE)" \
  --body "## What
<explain the fix>

## Why
<explain the root cause>

## Testing
- Added test: \`test_<name>\`
- All existing tests pass

Closes #$ISSUE"
```

### Step 8: Report
Tell the user:
- The root cause of the bug
- The test added
- The fix applied
- The PR URL
