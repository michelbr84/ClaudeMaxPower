---
name: finish-branch
description: Completes development work — verifies tests pass, presents merge/PR/keep/discard options, cleans up worktrees.
arguments:
  - name: base
    description: Base branch to integrate into (auto-detected if not specified)
    required: false
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Skill: finish-branch

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License). Original skill: `superpowers:finishing-a-development-branch`. See `ATTRIBUTION.md`.

Closes out a branch with a structured handoff. Verifies the work is actually green, presents
exactly four outcomes, and cleans up the worktree only when the chosen outcome justifies it.

**Announce at start:** "Using the finish-branch skill to complete this work."

## Workflow

### Step 1: Verify tests pass

Auto-detect the test command from the project. Run it. If it fails, STOP — do not proceed to
any of the later steps.

```bash
# Node.js
if [ -f package.json ] && grep -q '"test"' package.json; then
  npm test
# Python
elif [ -f pytest.ini ] || [ -f pyproject.toml ] || compgen -G "tests/test_*.py" > /dev/null; then
  pytest
# Rust
elif [ -f Cargo.toml ]; then
  cargo test
# Go
elif [ -f go.mod ]; then
  go test ./...
else
  echo "No recognized test configuration — ask the user how to run tests."
  exit 1
fi
```

If tests fail:
```
Tests are failing. Cannot finish this branch until they pass.
Failing tests:
  <summary of failures>
Fix the failures (or invoke /systematic-debugging), then re-run /finish-branch.
```

Do not advance to Step 2.

### Step 2: Determine base branch

```bash
if [ -n "${BASE:-}" ]; then
  BASE_BRANCH="$BASE"
elif git show-ref --verify --quiet refs/heads/main; then
  BASE_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
  BASE_BRANCH="master"
else
  echo "Could not auto-detect base branch. Ask the user which branch to integrate into."
  exit 1
fi
```

Capture the current feature branch and worktree path:

```bash
FEATURE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

### Step 3: Present four options

Print exactly this. No extra commentary, no preamble, no recap. The user has already done the
work — they want the four choices and nothing else.

```
Implementation complete. What would you like to do?
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work
Which option?
```

Wait for the user's answer before executing anything.

### Step 4: Execute the chosen option

#### Option 1 — Merge locally

```bash
git checkout "$BASE_BRANCH"
git pull --ff-only
git merge --no-ff "$FEATURE_BRANCH"
# Re-run tests on the merged result
npm test        # or pytest / cargo test / go test ./...
# If green, delete the feature branch
git branch -d "$FEATURE_BRANCH"
```

Then proceed to Step 5 for worktree cleanup.

If the merged-state tests fail: stop, report failures, do NOT delete the feature branch, do
NOT clean up the worktree.

#### Option 2 — Push and create PR

```bash
git push -u origin "$FEATURE_BRANCH"

gh pr create --base "$BASE_BRANCH" --title "<short title>" --body "$(cat <<'EOF'
## Summary
- <1-3 bullets describing what changed and why>

## Test Plan
- [ ] <how to verify the change>
- [ ] Full test suite passes locally

EOF
)"
```

Report the PR URL back to the user. Proceed to Step 5 (but Step 5 is a no-op for this option —
the branch must stay for review).

#### Option 3 — Keep as-is

Do **not** delete the branch. Do **not** clean up the worktree. Report:

```
Keeping branch <FEATURE_BRANCH>. Worktree preserved at <WORKTREE_PATH>.
```

Skip Step 5 entirely.

#### Option 4 — Discard

Destructive. Require a typed confirmation before doing anything.

```
This will permanently delete:
  - Branch: <FEATURE_BRANCH>
  - Worktree: <WORKTREE_PATH>
  - All uncommitted changes in the worktree

Type "discard" exactly to confirm, or anything else to cancel.
```

If and only if the user types `discard`:

```bash
# Move out of the worktree first (you cannot delete the one you are in)
cd "$(git worktree list | awk 'NR==1{print $1}')"
git branch -D "$FEATURE_BRANCH"
```

Then proceed to Step 5 for worktree removal.

Any answer other than the exact string `discard` cancels the operation. Report the cancellation
and stop.

### Step 5: Cleanup worktree

Worktree cleanup runs **only** for Options 1 (merged locally) and 4 (discarded). It does NOT
run for Options 2 (the PR needs the branch) or 3 (the user explicitly said to keep it).

```bash
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

If `git worktree remove` fails because the worktree is dirty or locked, report the error and
let the user decide — do not force-remove.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally    | Yes | No  | No  | Yes (-d, safe) |
| 2. Push and PR      | No  | Yes | Yes | No (PR needs it) |
| 3. Keep as-is       | No  | No  | Yes | No |
| 4. Discard          | No  | No  | No  | Yes (-D, forced, after typed confirm) |

## Common Mistakes

- **Skipping test verification.** Tests might be known-red in the user's head — run them
  anyway. Assumptions are how broken code ships.
- **Open-ended questions.** "What do you want to do next?" forces the user to invent the
  options. Present exactly the four. Let them pick a number.
- **Automatic worktree cleanup in wrong cases.** Cleaning the worktree after a PR push orphans
  the review workflow. Cleaning it after "keep as-is" ignores the user's explicit request.
- **No confirmation for discard.** Any discard path that doesn't require a typed `discard`
  token will eventually delete someone's work.
- **Deleting the feature branch before the merged tests are green.** If the merge breaks
  something, you want to be able to check out the feature branch and debug — not reconstruct
  it from reflog.

## Red Flags

- **Never** proceed with failing tests. "I know those are flaky" is not an exception. Fix or
  quarantine the flaky tests first.
- **Never** force-push without an explicit user request. `git push --force-with-lease` is
  acceptable only when the user asked for a rebase+push.
- **Never** delete work without a typed confirmation. Not "y", not "yes" — the specific word
  `discard`.
- **Never** merge to `main` or `master` directly if the project has a PR-required policy.
  Detect via `gh repo view --json defaultBranchRef,branchProtectionRules` and fall back to
  Option 2 if the base branch is protected.

## Integration with ClaudeMaxPower

- Called by `/subagent-dev` and `/assemble-team` after all implementation tasks are complete —
  this is the team's exit handoff
- Pairs with `/using-worktrees` — that skill creates the isolated workspace, this skill closes
  it down cleanly
- Works alongside the `code-reviewer` agent — Option 2's PR body is a natural input for an
  automated review pass before human reviewers look at it
- Honors the `.claude/settings.json` hooks — the `pre-tool-use.sh` guard will block any
  accidental force-push to `main`/`master`, backing up the red flag above
