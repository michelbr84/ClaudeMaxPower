---
name: review-pr
description: Full PR review — reads the diff, checks for bugs/security/tests/style, and posts a structured review comment via GitHub CLI.
arguments:
  - name: pr
    description: Pull request number
    required: true
  - name: repo
    description: "Repository in owner/repo format (default: $DEFAULT_REPO from .env)"
    required: false
allowed-tools:
  - Bash
  - Read
  - Grep
---

# Skill: review-pr

Perform a thorough code review of a GitHub pull request and post structured feedback.

## Arguments

- `--pr <number>` — PR number to review (required)
- `--repo <owner/repo>` — target repository (optional, defaults to `$DEFAULT_REPO`)

## Workflow

### Step 1: Load environment
```bash
[ -f .env ] && export $(grep -v '^#' .env | xargs)
REPO="${REPO:-$DEFAULT_REPO}"
```

### Step 2: Fetch PR metadata and diff
```bash
gh pr view $PR --repo $REPO
gh pr diff $PR --repo $REPO
```

Read:
- PR title and description
- Linked issues
- Labels and reviewers
- Full file diff

### Step 3: Analyze the diff

Evaluate the changes across these dimensions:

**Correctness**
- [ ] Logic errors or edge cases not handled?
- [ ] Off-by-one errors, null dereferences, race conditions?
- [ ] Error cases handled (not just happy path)?

**Security (OWASP Top 10 basics)**
- [ ] Any SQL built via string concatenation (SQL injection risk)?
- [ ] User input rendered directly in output (XSS risk)?
- [ ] Secrets or credentials in code or comments?
- [ ] New dependencies introduced? Are they from trusted sources?

**Tests**
- [ ] Are new features covered by tests?
- [ ] Are bug fixes accompanied by a regression test?
- [ ] Do the tests actually test what they claim?

**Style and maintainability**
- [ ] Consistent with project conventions (from CLAUDE.md)?
- [ ] Function/variable names clear and descriptive?
- [ ] Any obvious code duplication that could be extracted?

**Breaking changes**
- [ ] Does this change any public APIs or interfaces?
- [ ] Are all callers updated?
- [ ] Is there a migration path?

### Step 4: Compose structured review

Format your review as:

```
## Review: PR #$PR

**Verdict**: APPROVED | CHANGES REQUESTED | NEEDS DISCUSSION

### Summary
<1-2 sentence summary of what the PR does>

### ✅ Strengths
- <positive observation>

### ❌ Issues (must fix before merge)
- **[BLOCKING]** <file>:<line> — <issue description>

### ⚠ Suggestions (optional improvements)
- **[SUGGESTION]** <file>:<line> — <suggestion>

### 🔒 Security
- <any security observations, or "No security concerns found">

### 🧪 Test Coverage
- <assessment of test coverage>
```

### Step 5: Post the review
```bash
gh pr review $PR --repo $REPO \
  --comment \
  --body "<formatted review from Step 4>"
```

If blocking issues found:
```bash
gh pr review $PR --repo $REPO --request-changes --body "<review>"
```

If clean:
```bash
gh pr review $PR --repo $REPO --approve --body "<review>"
```

### Step 6: Report to user
Tell the user the verdict and list any blocking issues found.
