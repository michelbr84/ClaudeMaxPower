---
name: using-worktrees
description: Creates an isolated git worktree workspace before implementation. Systematic directory selection plus safety verification.
arguments:
  - name: branch
    description: New branch name to create (e.g., feat/user-auth)
    required: true
  - name: location
    description: Override default directory selection
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
---

# Skill: using-worktrees

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License). Original skill: `superpowers:using-git-worktrees`. See `ATTRIBUTION.md`.

Sets up an isolated git worktree so new work never contaminates the current checkout. Picks a
directory systematically, verifies gitignore safety, runs project setup, and confirms tests
pass on the baseline before returning.

**Announce at start:** "Using using-worktrees skill to set up an isolated workspace."

## Workflow

### Step 1: Directory selection

Walk this priority order. Stop at the first match.

1. If `.worktrees/` exists at the repo root — use it (preferred, hidden directory).
2. Else if `worktrees/` exists at the repo root — use it (alternative location).
3. Else check `CLAUDE.md` for a preference matching `worktree.*director` (case-insensitive).
4. Else ask the user to choose between:
   - Project-local: `.worktrees/` at the repo root
   - Global: `~/.config/claudemaxpower/worktrees/<project>/`

If **both** `.worktrees/` and `worktrees/` exist, prefer `.worktrees/`.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)

if [ -d "$REPO_ROOT/.worktrees" ]; then
  WORKTREE_DIR="$REPO_ROOT/.worktrees"
  LOCATION=local
elif [ -d "$REPO_ROOT/worktrees" ]; then
  WORKTREE_DIR="$REPO_ROOT/worktrees"
  LOCATION=local
elif grep -qiE "worktree.*director" "$REPO_ROOT/CLAUDE.md" 2>/dev/null; then
  # Parse the preference line from CLAUDE.md
  WORKTREE_DIR=$(grep -iE "worktree.*director" "$REPO_ROOT/CLAUDE.md" | head -1 | sed -E 's/.*: *//')
  LOCATION=local
else
  # Fall through to asking the user — do not silently pick
  echo "No worktree directory configured. Ask the user:"
  echo "  1) Project-local: .worktrees/"
  echo "  2) Global:        ~/.config/claudemaxpower/worktrees/<project>/"
fi
```

### Step 2: Safety verification (critical for project-local)

If the chosen directory lives inside the repo, it **must** be ignored by git. A worktree that
gets committed pollutes history with nested repositories and checkout metadata.

```bash
if [ "$LOCATION" = "local" ]; then
  IGNORE_NAME=$(basename "$WORKTREE_DIR")
  cd "$REPO_ROOT"
  if ! git check-ignore -q "$IGNORE_NAME"; then
    echo "$IGNORE_NAME is NOT ignored. Adding to .gitignore."
    printf '\n# Worktrees managed by ClaudeMaxPower\n%s/\n' "$IGNORE_NAME" >> .gitignore
    git add .gitignore
    git commit -m "chore: ignore worktree directory $IGNORE_NAME"
  fi
fi
```

For global directories (outside the repo), no gitignore check is required — they cannot be
committed.

**Why this matters:** A worktree committed to the repo creates subtle breakage — nested
`.git` metadata, circular references, and a very confusing diff for the next contributor.
Verify before you create; do not rely on cleanup.

### Step 3: Create the worktree

Detect the project name for global paths and create the branch.

```bash
project=$(basename "$REPO_ROOT")

# Resolve final path
if [ "$LOCATION" = "global" ]; then
  BASE="$HOME/.config/claudemaxpower/worktrees/$project"
  mkdir -p "$BASE"
  WORKTREE_PATH="$BASE/$BRANCH_NAME"
else
  WORKTREE_PATH="$WORKTREE_DIR/$BRANCH_NAME"
fi

git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
cd "$WORKTREE_PATH"
```

If the branch already exists, either switch to it (`git worktree add "$WORKTREE_PATH"
"$BRANCH_NAME"` without `-b`) or ask the user — do not silently overwrite.

### Step 4: Project setup

Auto-detect the ecosystem and install dependencies. Run **only** the one(s) that match.

```bash
# Node.js / JavaScript / TypeScript
if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then pnpm install
  elif [ -f yarn.lock ]; then yarn install
  else npm install
  fi
fi

# Rust
if [ -f Cargo.toml ]; then
  cargo build
fi

# Python
if [ -f pyproject.toml ] && command -v poetry >/dev/null 2>&1; then
  poetry install
elif [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

# Go
if [ -f go.mod ]; then
  go mod download
fi
```

If none of these files exist, report what was found and ask the user whether any setup is
needed — do not invent commands.

### Step 5: Verify a clean baseline

Run the project's tests **before** any implementation. A failing baseline means you cannot
distinguish "my change broke this" from "this was already broken," which defeats the purpose
of the worktree.

```bash
if [ -f package.json ] && grep -q '"test"' package.json; then
  TEST_CMD="npm test"
elif [ -f Cargo.toml ]; then
  TEST_CMD="cargo test"
elif [ -f pyproject.toml ] || [ -f pytest.ini ] || compgen -G "tests/test_*.py" > /dev/null; then
  TEST_CMD="pytest"
elif [ -f go.mod ]; then
  TEST_CMD="go test ./..."
fi

$TEST_CMD
```

If tests fail on the untouched baseline: stop, report the failures, and ask the user whether
to proceed regardless. Do not assume silence means go.

### Step 6: Report readiness

```
Worktree ready at <WORKTREE_PATH>, tests passing (<N> tests), ready to implement <feature>.
```

From this point on, all implementation happens inside `WORKTREE_PATH`. The original checkout
is untouched.

## Quick Reference

| Check | Priority | Behavior if Missing |
|-------|----------|---------------------|
| `.worktrees/` exists | 1 (preferred) | Try next option |
| `worktrees/` exists | 2 | Try next option |
| CLAUDE.md preference | 3 | Try next option |
| User choice | 4 (fallback) | Ask — do not guess |
| `.gitignore` covers dir | Required for local | Add + commit before proceeding |
| Dependency install | Auto by ecosystem | Ask user if ecosystem unknown |
| Baseline tests green | Required | Ask user before proceeding |

## Common Mistakes

- **Skipping the ignore verification.** "It will probably be ignored" is how worktree metadata
  lands in commits. Always run `git check-ignore -q` first.
- **Assuming the directory location.** Hardcoding `.worktrees/` breaks projects that chose
  `worktrees/` or a global directory. Walk the priority order every time.
- **Proceeding with failing baseline tests.** If the baseline is red, every later test result
  is ambiguous — you cannot tell which failures you caused.
- **Hardcoding setup commands.** `npm install` in a Python project is embarrassing; running
  every possible installer is wasteful. Detect the ecosystem first, then run exactly what
  matches.
- **Overwriting an existing branch.** `git worktree add -b` fails if the branch exists — do
  not suppress that error, ask the user.

## Integration with ClaudeMaxPower

- Called by `/brainstorming` after the user approves the plan — the worktree is where the plan
  is executed
- Called by `/subagent-dev` and `/assemble-team` before any implementation agent starts work,
  giving each agent an isolated workspace
- Pairs with `/finish-branch` for cleanup — that skill removes the worktree (Options 1 and 4)
  or preserves it (Options 2 and 3) based on the chosen outcome
- The `pre-tool-use.sh` hook's block on force-pushing `main`/`master` protects worktree-based
  workflows from accidentally promoting broken work
- Honors the project's `CLAUDE.md` as the source of truth for directory preferences — respects
  per-repo configuration automatically
