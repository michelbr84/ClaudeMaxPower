#!/usr/bin/env bash
# test-auto-dream.sh — Self-test scripts/auto-dream.sh in isolation.
#
# Verifies that auto-dream.sh behaves correctly across its trigger states.
# The test runs ENTIRELY in an isolated temporary directory: it never touches
# the user's real ~/.claude/projects/<slug>/memory tree, never touches the
# repo working tree, and never spawns network calls. git status must remain
# clean after exit.
#
# What is tested:
#   1. Missing memory dir              — exits 0 (graceful no-op)
#   2. Under-threshold (recent dream)  — exits 0, increments sessions_since,
#                                        does NOT rebuild MEMORY.md
#   3. Over-threshold (24h+, 5+ sess.) — exits 0, runs all 4 phases, rebuilds
#                                        MEMORY.md, resets state file
#   4. Stale lock (dead PID)           — exits 0, lock removed, dream runs
#   5. Live lock (running PID)         — exits 0, lock preserved, state
#                                        unchanged (skipped cleanly)
#
# What is NOT tested:
#   - Whether session-start hook actually triggers auto-dream.sh in production
#     (that's the harness's job; here we test auto-dream itself).
#   - The semantic correctness of the consolidation phases (what "stale" means
#     beyond file age; how to merge contradictory memories). Those decisions
#     are intentionally Claude's, not the script's — see docs/auto-dream-guide.md.
#
# Usage:
#   bash scripts/test-auto-dream.sh
#
# Exit codes:
#   0 — all tests passed
#   1 — at least one test failed
#   2 — auto-dream.sh not found (setup error)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUTO_DREAM="$REPO_ROOT/scripts/auto-dream.sh"

if [ ! -f "$AUTO_DREAM" ]; then
  echo -e "${RED}error:${NC} auto-dream.sh not found at $AUTO_DREAM" >&2
  exit 2
fi

# Snapshot the working-tree state so we can detect mutation at the end.
WORKTREE_SNAPSHOT=""
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  WORKTREE_SNAPSHOT="$(git -C "$REPO_ROOT" status --porcelain)"
fi

CMP_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/cmp-test-auto-dream.XXXXXX" 2>/dev/null \
              || mktemp -d -t cmp-test-auto-dream.XXXXXX)"
trap 'rm -rf "$CMP_TMPDIR"' EXIT

pass=0
fail=0

note() { echo -e "${BLUE}--${NC} $1"; }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "  ${GREEN}[PASS]${NC} $label"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $label (expected '$expected', got '$actual')"
    fail=$((fail + 1))
  fi
}

# Read an integer field from the JSON state file. Mirrors auto-dream.sh's own
# extraction approach so we test what auto-dream actually wrote.
read_state_int() {
  local file="$1" key="$2"
  grep -o "\"${key}\":[0-9]*" "$file" 2>/dev/null \
    | head -1 \
    | grep -o '[0-9]*' \
    || echo ""
}

# Make a fresh isolated memory directory under CMP_TMPDIR.
make_memory_dir() {
  local name="$1"
  local dir="$CMP_TMPDIR/$name"
  mkdir -p "$dir"
  echo "$dir"
}

# Write a state file with a specific epoch and session count.
write_state() {
  local mem="$1" epoch="$2" sessions="$3"
  cat > "$mem/.dream-state.json" <<EOF
{"last_dream_epoch":${epoch},"sessions_since":${sessions},"last_check":"2026-04-01T00:00:00Z"}
EOF
}

# Write a sample memory markdown file with the frontmatter auto-dream reads.
write_sample_memory() {
  local mem="$1" name="$2" type="$3"
  cat > "$mem/${name}.md" <<EOF
---
name: ${name}
description: Sample memory for testing
type: ${type}
---

Sample content body.
EOF
}

# Run auto-dream.sh against a memory dir. Returns the exit code on stdout.
run_auto_dream() {
  local mem="$1"
  local rc=0
  set +e
  CLAUDE_MEMORY_DIR="$mem" CLAUDE_PROJECT_DIR="$CMP_TMPDIR/fake-project" \
    bash "$AUTO_DREAM" >/dev/null 2>&1
  rc=$?
  set -e
  echo "$rc"
}

# Produce a PID that is guaranteed to no longer exist: spawn a no-op
# subshell, capture its PID, wait for it to terminate. The captured number
# is now a dead PID. More reliable than picking a "high" PID arbitrarily.
make_dead_pid() {
  ( exit 0 ) &
  local p=$!
  wait "$p" 2>/dev/null || true
  echo "$p"
}

echo ""
echo -e "${BLUE}== ClaudeMaxPower auto-dream self-test ==${NC}"
echo "Workspace: $CMP_TMPDIR"
echo ""

NOW=$(date +%s)
STALE_EPOCH=$((NOW - 25 * 3600))   # 25 hours ago — over the 24h threshold
RECENT_EPOCH="$NOW"                # right now — under threshold

# 1. Missing memory dir → graceful no-op ─────────────────────────────────────
note "missing memory dir → graceful no-op"
rc=$(run_auto_dream "$CMP_TMPDIR/does-not-exist")
assert_eq "exits 0 when memory dir is absent" "0" "$rc"

# 2. Under-threshold → no-op, sessions_since increments ─────────────────────
note "under-threshold (recent dream) → increments sessions_since, no consolidation"
mem=$(make_memory_dir under-threshold)
write_state "$mem" "$RECENT_EPOCH" 0
write_sample_memory "$mem" "user_profile" "user"

rc=$(run_auto_dream "$mem")
assert_eq "exits 0 in under-threshold case" "0" "$rc"

new_sessions=$(read_state_int "$mem/.dream-state.json" "sessions_since")
assert_eq "sessions_since incremented (0 → 1)" "1" "$new_sessions"

new_epoch=$(read_state_int "$mem/.dream-state.json" "last_dream_epoch")
assert_eq "last_dream_epoch unchanged" "$RECENT_EPOCH" "$new_epoch"

# Phase-4 marker is the only reliable signal that consolidation ran. CI's
# under-threshold path never writes files_processed.
if grep -q '"files_processed"' "$mem/.dream-state.json"; then
  echo -e "  ${RED}[FAIL]${NC} consolidation should NOT have run"
  fail=$((fail + 1))
else
  echo -e "  ${GREEN}[PASS]${NC} consolidation did NOT run"
  pass=$((pass + 1))
fi

if [ -f "$mem/MEMORY.md" ]; then
  echo -e "  ${RED}[FAIL]${NC} MEMORY.md should NOT have been created"
  fail=$((fail + 1))
else
  echo -e "  ${GREEN}[PASS]${NC} MEMORY.md not created in under-threshold case"
  pass=$((pass + 1))
fi

# 3. Over-threshold → consolidation runs ───────────────────────────────────
note "over-threshold (>24h, 5+ sessions) → consolidation runs, MEMORY.md rebuilt"
mem=$(make_memory_dir over-threshold)
write_state "$mem" "$STALE_EPOCH" 10
write_sample_memory "$mem" "user_profile" "user"
write_sample_memory "$mem" "feedback_one"  "feedback"

rc=$(run_auto_dream "$mem")
assert_eq "exits 0 in over-threshold case" "0" "$rc"

after_epoch=$(read_state_int "$mem/.dream-state.json" "last_dream_epoch")
if [ -n "$after_epoch" ] && [ "$after_epoch" -gt "$STALE_EPOCH" ]; then
  echo -e "  ${GREEN}[PASS]${NC} last_dream_epoch advanced past stale value"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} last_dream_epoch did not advance (stale=$STALE_EPOCH, now=$after_epoch)"
  fail=$((fail + 1))
fi

after_sessions=$(read_state_int "$mem/.dream-state.json" "sessions_since")
assert_eq "sessions_since reset to 0 after consolidation" "0" "$after_sessions"

files_processed=$(read_state_int "$mem/.dream-state.json" "files_processed")
assert_eq "files_processed records 2 input files" "2" "$files_processed"

if [ -f "$mem/MEMORY.md" ] && grep -q "^# Memory Index" "$mem/MEMORY.md"; then
  echo -e "  ${GREEN}[PASS]${NC} MEMORY.md rebuilt with header"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} MEMORY.md missing or malformed"
  fail=$((fail + 1))
fi

if grep -q "## User" "$mem/MEMORY.md" 2>/dev/null \
   && grep -q "## Feedback" "$mem/MEMORY.md" 2>/dev/null; then
  echo -e "  ${GREEN}[PASS]${NC} MEMORY.md groups entries by type"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} MEMORY.md type sections missing"
  fail=$((fail + 1))
fi

# 4. Stale lock (dead PID) → cleared, dream runs ───────────────────────────
note "stale lock (dead PID) → cleared, consolidation runs"
mem=$(make_memory_dir stale-lock)
write_state "$mem" "$STALE_EPOCH" 10
write_sample_memory "$mem" "user_profile" "user"

dead_pid=$(make_dead_pid)
echo "$dead_pid" > "$mem/.dream.lock"

rc=$(run_auto_dream "$mem")
assert_eq "exits 0 with stale lock present" "0" "$rc"

if [ ! -f "$mem/.dream.lock" ]; then
  echo -e "  ${GREEN}[PASS]${NC} stale lock removed (cleanup trap fired)"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} stale lock NOT removed"
  fail=$((fail + 1))
fi

if [ -f "$mem/MEMORY.md" ]; then
  echo -e "  ${GREEN}[PASS]${NC} consolidation ran past the stale lock"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} consolidation did not run"
  fail=$((fail + 1))
fi

# 5. Live lock (running PID) → skipped, state unchanged ────────────────────
# We use the test script's own PID ($$). Since this script is alive while it
# spawns auto-dream, kill -0 $$ from inside auto-dream succeeds → "another
# instance is running" → exit 0 with state preserved.
note "live lock (running PID) → skipped cleanly, state unchanged"
mem=$(make_memory_dir live-lock)
write_state "$mem" "$STALE_EPOCH" 10
write_sample_memory "$mem" "user_profile" "user"

echo "$$" > "$mem/.dream.lock"

rc=$(run_auto_dream "$mem")
assert_eq "exits 0 when another instance holds the lock" "0" "$rc"

unchanged_epoch=$(read_state_int "$mem/.dream-state.json" "last_dream_epoch")
assert_eq "last_dream_epoch unchanged (skipped run)" "$STALE_EPOCH" "$unchanged_epoch"

if [ -f "$mem/.dream.lock" ]; then
  echo -e "  ${GREEN}[PASS]${NC} live lock preserved (no cleanup on skip)"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} live lock was incorrectly removed"
  fail=$((fail + 1))
fi

# Manually clear our own lock — we wrote it.
rm -f "$mem/.dream.lock"

# Mutation guard ────────────────────────────────────────────────────────────
echo ""
note "Working-tree mutation guard"

cd "$REPO_ROOT"
if [ -n "$WORKTREE_SNAPSHOT" ]; then
  CURRENT_SNAPSHOT="$(git status --porcelain)"
  if [ "$CURRENT_SNAPSHOT" = "$WORKTREE_SNAPSHOT" ]; then
    echo -e "  ${GREEN}[PASS]${NC} repo working tree unchanged"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} repo working tree was mutated by auto-dream tests:"
    diff <(echo "$WORKTREE_SNAPSHOT") <(echo "$CURRENT_SNAPSHOT") || true
    fail=$((fail + 1))
  fi
else
  echo -e "  ${YELLOW}[SKIP]${NC} not inside a git repo — cannot diff state"
fi

# Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
if [ "$fail" -eq 0 ]; then
  echo -e "${GREEN}All $pass auto-dream self-tests passed.${NC}"
  exit 0
else
  echo -e "${RED}$fail auto-dream self-test(s) failed${NC} ($pass passed)."
  exit 1
fi
