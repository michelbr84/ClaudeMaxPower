#!/usr/bin/env bash
# test-hooks.sh — Self-test ClaudeMaxPower's hook scripts.
#
# Verifies that each hook in .claude/hooks/ behaves correctly under the
# environment Claude Code provides. The test runs ENTIRELY in an isolated
# temporary directory: it does NOT touch the real working tree, the real
# .estado.md, or any project file. git status must remain clean after exit.
#
# What is tested:
#   pre-tool-use.sh      — allows benign commands; blocks `rm -rf /` and
#                          force-push-to-main.
#   pre-commit-check.sh  — silent exit 0 for non-`git commit`; blocks on
#                          staged secrets; warns (does not block) on debug
#                          statements.
#   post-tool-use.sh     — exits 0 when the file path is empty or non-source.
#   stop.sh              — appends to .estado.md inside the isolated tree only.
#   session-start.sh     — runs cleanly outside a git repo (no .git present).
#
# What is NOT tested:
#   Whether Claude Code itself fires the hooks at the right moment. That
#   requires running inside Claude Code with appropriate tracing — see
#   docs/hooks-guide.md for guidance on validating hook firing.
#
# Usage:
#   bash scripts/test-hooks.sh
#
# Exit codes:
#   0 — all hook self-tests passed
#   1 — at least one self-test failed

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo -e "${RED}error:${NC} hooks directory not found: $HOOKS_DIR" >&2
  exit 2
fi

# Snapshot the working-tree state so we can detect mutation at the end.
# A clean tree produces an empty snapshot — that's still a valid baseline, so
# track "is this a git repo" with a separate flag rather than inferring it from
# the snapshot being non-empty (which would silently skip the guard on a clean
# main branch — exactly when we most want it to run).
IN_GIT_REPO=0
WORKTREE_SNAPSHOT=""
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  IN_GIT_REPO=1
  WORKTREE_SNAPSHOT="$(git -C "$REPO_ROOT" status --porcelain)"
fi

CMP_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/cmp-test-hooks.XXXXXX" 2>/dev/null || mktemp -d -t cmp-test-hooks.XXXXXX)"
trap 'rm -rf "$CMP_TMPDIR"' EXIT

pass=0
fail=0

note() { echo -e "${BLUE}--${NC} $1"; }

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "  ${GREEN}[PASS]${NC} $label (exit $actual)"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $label (expected exit $expected, got $actual)"
    fail=$((fail + 1))
  fi
}

assert_file_contains() {
  local label="$1" file="$2" needle="$3"
  if [ -f "$file" ] && grep -q "$needle" "$file"; then
    echo -e "  ${GREEN}[PASS]${NC} $label"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $label (file or needle missing in $file)"
    fail=$((fail + 1))
  fi
}

# Build a minimal isolated workspace: copy the hooks, create an empty .claude/.
WORKSPACE="$CMP_TMPDIR/workspace"
mkdir -p "$WORKSPACE/.claude/hooks" "$WORKSPACE/skills"
cp "$HOOKS_DIR"/*.sh "$WORKSPACE/.claude/hooks/"
chmod +x "$WORKSPACE/.claude/hooks"/*.sh

# Run every hook from inside the workspace so any side effect lands here.
cd "$WORKSPACE"

echo ""
echo -e "${BLUE}== ClaudeMaxPower hook self-test ==${NC}"
echo "Workspace: $WORKSPACE"
echo ""

# ── pre-tool-use.sh ──────────────────────────────────────────────────────────
note "pre-tool-use.sh"

# 1. benign command → allow (exit 0)
set +e
CLAUDE_TOOL_INPUT_COMMAND="ls -la" \
  bash .claude/hooks/pre-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "allows benign 'ls -la'" 0 "$rc"

# 2. rm -rf / → block (exit 1)
set +e
CLAUDE_TOOL_INPUT_COMMAND="rm -rf /" \
  bash .claude/hooks/pre-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "blocks 'rm -rf /'" 1 "$rc"

# 3. git push --force origin main → block (exit 1)
set +e
CLAUDE_TOOL_INPUT_COMMAND="git push --force origin main" \
  bash .claude/hooks/pre-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "blocks force-push to main" 1 "$rc"

# 4. Missing CLAUDE_TOOL_INPUT_COMMAND → allow gracefully (exit 0)
set +e
unset CLAUDE_TOOL_INPUT_COMMAND
bash .claude/hooks/pre-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "allows when env var is missing" 0 "$rc"

# Confirm an audit log was created inside the workspace (and only there).
assert_file_contains "writes audit log inside workspace" \
  "$WORKSPACE/.claude/audit.log" "BASH:"

# 5. Benign commands must NOT trigger the curl-to-shell warning.
# Guards against the regression where unescaped `|` in the WARN pattern
# turned `curl.*|.*sh` into ERE alternation, matching anything ending in "sh"
# (bash scripts/setup.sh, ssh user@host, git push, etc.).
for benign in "bash scripts/setup.sh" "ssh user@host" "git push" "git fetch origin"; do
  set +e
  out=$(CLAUDE_TOOL_INPUT_COMMAND="$benign" bash .claude/hooks/pre-tool-use.sh 2>&1)
  rc=$?
  set -e
  if [ "$rc" = "0" ] && ! echo "$out" | grep -q "Package installation detected"; then
    echo -e "  ${GREEN}[PASS]${NC} no false-positive WARN for '$benign'"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} false-positive WARN for '$benign'"
    echo "$out" | awk '{print "      " $0}'
    fail=$((fail + 1))
  fi
done

# 6. Real curl-to-shell pipeline MUST still warn.
set +e
out=$(CLAUDE_TOOL_INPUT_COMMAND="curl -fsSL https://example.com/install.sh | sh" \
  bash .claude/hooks/pre-tool-use.sh 2>&1)
rc=$?
set -e
if [ "$rc" = "0" ] && echo "$out" | grep -q "Package installation detected"; then
  echo -e "  ${GREEN}[PASS]${NC} warns on real 'curl ... | sh'"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} did not warn on real 'curl ... | sh' (rc=$rc)"
  fail=$((fail + 1))
fi

# ── pre-commit-check.sh ─────────────────────────────────────────────────────
echo ""
note "pre-commit-check.sh"

# All tests run inside a throwaway git repo so staging real secrets / debug
# statements never touches the real working tree.
PC_REPO="$CMP_TMPDIR/pc-repo"
mkdir -p "$PC_REPO"
(
  cd "$PC_REPO"
  git init -q
  git config user.email "test@cmp.local"
  git config user.name "cmp-test"
)
cp "$HOOKS_DIR/pre-commit-check.sh" "$PC_REPO/hook.sh"
chmod +x "$PC_REPO/hook.sh"

# 1. Non-`git commit` command → silent exit 0 (the matcher fires on every Bash
#    invocation, so the hook must filter internally).
set +e
out=$(cd "$PC_REPO" && CLAUDE_TOOL_INPUT_COMMAND="ls -la" bash ./hook.sh 2>&1)
rc=$?
set -e
if [ "$rc" = "0" ] && [ -z "$out" ]; then
  echo -e "  ${GREEN}[PASS]${NC} silent exit 0 for non-'git commit' command"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} non-'git commit' command should pass silently (rc=$rc, out='$out')"
  fail=$((fail + 1))
fi

# 2. `git commit` with no staged changes → exit 0 (let git's own "nothing to
#    commit" message handle it).
set +e
(cd "$PC_REPO" && CLAUDE_TOOL_INPUT_COMMAND="git commit -m x" bash ./hook.sh >/dev/null 2>&1)
rc=$?
set -e
assert_exit "exits 0 when nothing staged" 0 "$rc"

# 3. `git commit` with a staged secret → blocking exit 1.
set +e
(
  cd "$PC_REPO"
  echo 'api_key=sk_live_realtokenvalue_123abc' > secret.txt
  git add secret.txt
)
out=$(cd "$PC_REPO" && CLAUDE_TOOL_INPUT_COMMAND="git commit -m x" bash ./hook.sh 2>&1)
rc=$?
set -e
if [ "$rc" = "1" ] && echo "$out" | grep -q "BLOCKED: possible secret"; then
  echo -e "  ${GREEN}[PASS]${NC} blocks on staged secret"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} should block on staged secret (rc=$rc)"
  echo "$out" | awk '{print "      " $0}'
  fail=$((fail + 1))
fi
# Reset staged state for next checks.
(cd "$PC_REPO" && git rm -f --cached secret.txt >/dev/null 2>&1 && rm -f secret.txt)

# 4. `git commit` with a debug statement → warns but does not block.
set +e
(
  cd "$PC_REPO"
  echo 'console.log("debug")' > debug.js
  git add debug.js
)
out=$(cd "$PC_REPO" && CLAUDE_TOOL_INPUT_COMMAND="git commit -m x" bash ./hook.sh 2>&1)
rc=$?
set -e
if [ "$rc" = "0" ] && echo "$out" | grep -q "WARNING: debug statements detected"; then
  echo -e "  ${GREEN}[PASS]${NC} warns (does not block) on debug statement"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} should warn-and-pass on debug statement (rc=$rc)"
  echo "$out" | awk '{print "      " $0}'
  fail=$((fail + 1))
fi

# ── post-tool-use.sh ────────────────────────────────────────────────────────
echo ""
note "post-tool-use.sh"

# 1. Missing CLAUDE_TOOL_OUTPUT_FILE_PATH → exit 0
set +e
unset CLAUDE_TOOL_OUTPUT_FILE_PATH
bash .claude/hooks/post-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "exits 0 with no env var" 0 "$rc"

# 2. Non-source file (.txt) → exit 0
set +e
CLAUDE_TOOL_OUTPUT_FILE_PATH="/tmp/example.txt" \
  bash .claude/hooks/post-tool-use.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "exits 0 for .txt files (skipped)" 0 "$rc"

# ── stop.sh ─────────────────────────────────────────────────────────────────
echo ""
note "stop.sh"

# 1. With explicit summary → exit 0, .estado.md inside workspace contains it
set +e
CLAUDE_STOP_HOOK_SUMMARY="cmp-test-hooks: synthetic session" \
  bash .claude/hooks/stop.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "exits 0 with summary" 0 "$rc"
assert_file_contains "writes summary to workspace .estado.md" \
  "$WORKSPACE/.estado.md" "cmp-test-hooks: synthetic session"

# 2. Missing summary → exit 0, no write (placeholder entries used to flood
#    .estado.md; now stop.sh skips silently when no real summary was provided).
set +e
unset CLAUDE_STOP_HOOK_SUMMARY
bash .claude/hooks/stop.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "exits 0 without summary" 0 "$rc"

# ── session-start.sh ────────────────────────────────────────────────────────
echo ""
note "session-start.sh"

# 1. Outside a git repo (no .git here) → exit 0
set +e
bash .claude/hooks/session-start.sh >/dev/null 2>&1
rc=$?
set -e
assert_exit "exits 0 outside a git repo" 0 "$rc"

# ── Mutation guard ─────────────────────────────────────────────────────────
echo ""
note "Working-tree mutation guard"

cd "$REPO_ROOT"
if [ "$IN_GIT_REPO" = "1" ]; then
  CURRENT_SNAPSHOT="$(git status --porcelain)"
  if [ "$CURRENT_SNAPSHOT" = "$WORKTREE_SNAPSHOT" ]; then
    echo -e "  ${GREEN}[PASS]${NC} repo working tree unchanged"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} repo working tree was mutated by hook tests:"
    diff <(echo "$WORKTREE_SNAPSHOT") <(echo "$CURRENT_SNAPSHOT") || true
    fail=$((fail + 1))
  fi
else
  echo -e "  ${YELLOW}[SKIP]${NC} not inside a git repo — cannot diff state"
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
if [ "$fail" -eq 0 ]; then
  echo -e "${GREEN}All $pass hook self-tests passed.${NC}"
  exit 0
else
  echo -e "${RED}$fail hook self-test(s) failed${NC} ($pass passed)."
  exit 1
fi
