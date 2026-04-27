#!/usr/bin/env bash
# test-hooks.sh — Self-test ClaudeMaxPower's hook scripts.
#
# Verifies that each hook in .claude/hooks/ behaves correctly under the
# environment Claude Code provides. The test runs ENTIRELY in an isolated
# temporary directory: it does NOT touch the real working tree, the real
# .estado.md, or any project file. git status must remain clean after exit.
#
# What is tested:
#   pre-tool-use.sh   — allows benign commands; blocks `rm -rf /` and
#                       force-push-to-main.
#   post-tool-use.sh  — exits 0 when the file path is empty or non-source.
#   stop.sh           — appends to .estado.md inside the isolated tree only.
#   session-start.sh  — runs cleanly outside a git repo (no .git present).
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
WORKTREE_SNAPSHOT=""
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
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

# 2. Missing summary → exit 0, file appended with default text
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
if [ -n "$WORKTREE_SNAPSHOT" ]; then
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
