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

### Step 1: Load environment and gate on required arguments
```bash
[ -f .env ] && export $(grep -v '^#' .env | xargs)
REPO="${REPO:-$DEFAULT_REPO}"
```

If `REPO` is still empty, **stop and ask the user** (use AskUserQuestion if available, or
prompt directly): "Which repository should I target? Format: `owner/repo`."
Do not proceed past Step 1 with an empty `REPO`.

If `PR` is missing, ask the user for the PR number before continuing.

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

### Step 3: Analyze the diff against the review checklist

Read the full checklist in `skills/references/review-pr-checklist.md` and apply each section
(Correctness, Security, Tests, Style, Breaking changes, Operational) to the diff. The
checklist lives in a separate file so this skill body stays lean and the checklist itself
can evolve independently.

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

### Step 5: Confirm before posting

Show the drafted review to the user and **ask** before posting:

```
I've drafted the review. Choose:
  1) Post as-is
  2) Edit (tell me what to change)
  3) Cancel (don't post)
```

Wait for the user's choice. Do not skip this step — posting a review is a public, hard-to-
reverse action.

### Step 6: Post the review (only if user chose option 1)

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

### Step 7: Report to user
Tell the user the verdict and list any blocking issues found.

**Feedback:** Did this skill do what you needed? Reply with a 1–10 rating, what slowed you
down, or a faster path from where you started to where you ended.
