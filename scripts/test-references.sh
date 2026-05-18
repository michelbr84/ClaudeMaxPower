#!/usr/bin/env bash
# test-references.sh — Self-test the shared scripts under skills/references/.
#
# Mirrors the structure of scripts/test-hooks.sh: every assertion runs against
# a synthetic input prepared in an isolated temp workspace, the real working
# tree is never mutated, and a mutation guard at the end fails the run if any
# tracked file changed.
#
# What is tested:
#   load-env-and-resolve-repo.sh   — empty .env case, DEFAULT_REPO fallback,
#                                    quoted values (the xargs-bug regression).
#   detect-stack.sh                — none, single stack, multi-stack, bad dir.
#   detect-cmp-installation.sh     — full repo (yes), empty dir (no),
#                                    partial markers (no).
#   detect-project-kind.sh         — empty dir (new), dir with source tree
#                                    (existing).
#   check-spec-gate.sh             — no spec (exit 1), spec present (exit 0
#                                    with path).
#   route-goal.sh                  — single match, ambiguous, no match, no
#                                    input.
#   find-test-file.sh              — no test (exit 1), conventional test
#                                    found (exit 0), bad input (exit 2).
#   update-docs-index.sh           — empty dir (exit 1), dir with modules
#                                    (writes README.md with table).
#   run-tests.sh                   — bad target (exit 3), unsupported stack
#                                    (exit 2 with hint), python stack routes
#                                    to pytest (verified via dry-runnable env).
#
# Usage:
#   bash scripts/test-references.sh
#
# Exit codes:
#   0 — all reference self-tests passed
#   1 — at least one self-test failed

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF_DIR="$REPO_ROOT/skills/references"

if [ ! -d "$REF_DIR" ]; then
  echo -e "${RED}error:${NC} references directory not found: $REF_DIR" >&2
  exit 2
fi

# Mutation guard — same pattern as test-hooks.sh.
IN_GIT_REPO=0
WORKTREE_SNAPSHOT=""
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  IN_GIT_REPO=1
  WORKTREE_SNAPSHOT="$(git -C "$REPO_ROOT" status --porcelain)"
fi

CMP_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/cmp-test-refs.XXXXXX" 2>/dev/null || mktemp -d -t cmp-test-refs.XXXXXX)"
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

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    echo -e "  ${GREEN}[PASS]${NC} $label"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $label (string '$needle' not found in output)"
    echo "$haystack" | head -3 | awk '{print "      " $0}'
    fail=$((fail + 1))
  fi
}

echo ""
echo -e "${BLUE}== ClaudeMaxPower references self-test ==${NC}"
echo "Tmp workspace: $CMP_TMPDIR"
echo ""

# ── load-env-and-resolve-repo.sh ─────────────────────────────────────────────
note "load-env-and-resolve-repo.sh"

# 1. No .env in cwd → REPO ends up empty.
WS="$CMP_TMPDIR/load-env-empty"; mkdir -p "$WS"
set +e
out=$( cd "$WS" && eval "$(bash "$REF_DIR/load-env-and-resolve-repo.sh")"; echo "REPO=$REPO" )
rc=$?
set -e
assert_exit "no .env -> script exits 0" 0 "$rc"
assert_eq   "no .env -> REPO is empty" "REPO=" "$out"

# 2. .env with DEFAULT_REPO → REPO resolves to it.
WS="$CMP_TMPDIR/load-env-default"; mkdir -p "$WS"
echo "DEFAULT_REPO=owner/repo" > "$WS/.env"
set +e
out=$( cd "$WS" && eval "$(bash "$REF_DIR/load-env-and-resolve-repo.sh")"; echo "REPO=$REPO" )
rc=$?
set -e
assert_eq "DEFAULT_REPO -> REPO resolves" "REPO=owner/repo" "$out"

# 3. .env with quoted value containing spaces — the bug the new script fixes.
# Old `xargs`-based loader broke on this; new line-by-line loader handles it.
WS="$CMP_TMPDIR/load-env-quoted"; mkdir -p "$WS"
cat > "$WS/.env" <<'EOF'
# a comment line
DEFAULT_REPO="owner/repo"
EOF
set +e
out=$( cd "$WS" && eval "$(bash "$REF_DIR/load-env-and-resolve-repo.sh")"; echo "REPO=$REPO" )
rc=$?
set -e
assert_eq "comment + quoted value parse cleanly" "REPO=owner/repo" "$out"

# ── detect-stack.sh ──────────────────────────────────────────────────────────
note "detect-stack.sh"

# 1. Empty dir → "none"
WS="$CMP_TMPDIR/stack-empty"; mkdir -p "$WS"
out=$(bash "$REF_DIR/detect-stack.sh" "$WS")
assert_eq "empty dir -> none" "none" "$out"

# 2. package.json only → "node"
WS="$CMP_TMPDIR/stack-node"; mkdir -p "$WS"
echo "{}" > "$WS/package.json"
out=$(bash "$REF_DIR/detect-stack.sh" "$WS")
assert_eq "package.json -> node" "node" "$out"

# 3. package.json + go.mod → "node,go" (order-stable)
WS="$CMP_TMPDIR/stack-multi"; mkdir -p "$WS"
echo "{}" > "$WS/package.json"
echo "module x" > "$WS/go.mod"
out=$(bash "$REF_DIR/detect-stack.sh" "$WS")
assert_eq "node + go -> node,go (order-stable)" "node,go" "$out"

# 4. Bad dir → exit 2
set +e
bash "$REF_DIR/detect-stack.sh" "$CMP_TMPDIR/does-not-exist" >/dev/null 2>&1
rc=$?
set -e
assert_exit "nonexistent dir -> exit 2" 2 "$rc"

# ── detect-cmp-installation.sh ───────────────────────────────────────────────
note "detect-cmp-installation.sh"

# 1. Full repo → "yes"
out=$(bash "$REF_DIR/detect-cmp-installation.sh" "$REPO_ROOT")
assert_eq "real repo -> yes" "yes" "$out"

# 2. Empty dir → "no" (no markers at all)
WS="$CMP_TMPDIR/cmp-empty"; mkdir -p "$WS"
out=$(bash "$REF_DIR/detect-cmp-installation.sh" "$WS")
assert_eq "empty dir -> no" "no" "$out"

# 3. Two of three markers but CLAUDE.md missing the magic string → "no"
WS="$CMP_TMPDIR/cmp-partial"; mkdir -p "$WS/.claude/hooks" "$WS/skills"
touch "$WS/.claude/hooks/session-start.sh" "$WS/skills/assemble-team.md"
echo "# Some other project" > "$WS/CLAUDE.md"
out=$(bash "$REF_DIR/detect-cmp-installation.sh" "$WS")
assert_eq "CLAUDE.md missing tag -> no" "no" "$out"

# ── detect-project-kind.sh ───────────────────────────────────────────────────
note "detect-project-kind.sh"

# 1. Empty dir → "new"
WS="$CMP_TMPDIR/kind-empty"; mkdir -p "$WS"
out=$(bash "$REF_DIR/detect-project-kind.sh" "$WS")
assert_eq "empty dir -> new" "new" "$out"

# 2. Dir with src/ → "existing" (source-tree marker)
WS="$CMP_TMPDIR/kind-src"; mkdir -p "$WS/src"
out=$(bash "$REF_DIR/detect-project-kind.sh" "$WS")
assert_eq "src/ present -> existing" "existing" "$out"

# 3. Dir with non-CMP README → "existing"
WS="$CMP_TMPDIR/kind-readme"; mkdir -p "$WS"
echo "# My App" > "$WS/README.md"
out=$(bash "$REF_DIR/detect-project-kind.sh" "$WS")
assert_eq "non-CMP README -> existing" "existing" "$out"

# ── check-spec-gate.sh ───────────────────────────────────────────────────────
note "check-spec-gate.sh"

# 1. No specs → exit 1
WS="$CMP_TMPDIR/spec-empty"; mkdir -p "$WS"
set +e
bash "$REF_DIR/check-spec-gate.sh" "$WS" >/dev/null 2>&1
rc=$?
set -e
assert_exit "no spec -> exit 1" 1 "$rc"

# 2. Spec present → exit 0, prints path
WS="$CMP_TMPDIR/spec-present"; mkdir -p "$WS"
echo "# spec" > "$WS/2026-05-18-foo-design.md"
set +e
out=$(bash "$REF_DIR/check-spec-gate.sh" "$WS")
rc=$?
set -e
assert_exit "spec present -> exit 0" 0 "$rc"
assert_contains "spec path printed to stdout" "$out" "foo-design.md"

# ── route-goal.sh ────────────────────────────────────────────────────────────
note "route-goal.sh"

# 1. Single match: "add feature" → brainstorming, exit 0
set +e
out=$(bash "$REF_DIR/route-goal.sh" "add user authentication")
rc=$?
set -e
assert_exit "feature language -> exit 0" 0 "$rc"
assert_contains "feature -> /superpowers:brainstorming" "$out" "/superpowers:brainstorming"

# 2. Ambiguous: bug + issue number → exit 1
set +e
out=$(bash "$REF_DIR/route-goal.sh" "fix the login bug #42")
rc=$?
set -e
assert_exit "ambiguous -> exit 1" 1 "$rc"

# 3. No match → exit 3
set +e
bash "$REF_DIR/route-goal.sh" "wibble wobble" >/dev/null 2>&1
rc=$?
set -e
assert_exit "unmatched goal -> exit 3" 3 "$rc"

# 4. No input → exit 2
set +e
bash "$REF_DIR/route-goal.sh" "" >/dev/null 2>&1
rc=$?
set -e
assert_exit "empty goal -> exit 2" 2 "$rc"

# ── find-test-file.sh ────────────────────────────────────────────────────────
note "find-test-file.sh"

# 1. No source file → exit 2
set +e
bash "$REF_DIR/find-test-file.sh" "$CMP_TMPDIR/nope.py" >/dev/null 2>&1
rc=$?
set -e
assert_exit "missing source file -> exit 2" 2 "$rc"

# 2. Source exists but no matching test → exit 1
WS="$CMP_TMPDIR/find-test-none"; mkdir -p "$WS/src"
touch "$WS/src/foo.py"
set +e
bash "$REF_DIR/find-test-file.sh" "$WS/src/foo.py" >/dev/null 2>&1
rc=$?
set -e
assert_exit "no matching test -> exit 1" 1 "$rc"

# 3. src-layout: src/foo.py + tests/test_foo.py → exit 0, prints test path
WS="$CMP_TMPDIR/find-test-srclayout"; mkdir -p "$WS/src" "$WS/tests"
touch "$WS/src/foo.py" "$WS/tests/test_foo.py"
set +e
out=$(bash "$REF_DIR/find-test-file.sh" "$WS/src/foo.py")
rc=$?
set -e
assert_exit "src-layout test found -> exit 0" 0 "$rc"
assert_contains "src-layout test path printed" "$out" "tests/test_foo.py"

# ── update-docs-index.sh ─────────────────────────────────────────────────────
note "update-docs-index.sh"

# 1. Empty dir → exit 1 (nothing to index)
WS="$CMP_TMPDIR/docs-empty"; mkdir -p "$WS"
set +e
bash "$REF_DIR/update-docs-index.sh" "$WS" >/dev/null 2>&1
rc=$?
set -e
assert_exit "empty docs dir -> exit 1" 1 "$rc"

# 2. Two modules → exit 0, README.md written with both entries
WS="$CMP_TMPDIR/docs-modules"; mkdir -p "$WS"
cat > "$WS/alpha.md" <<'EOF'
# alpha

> First module description.
EOF
cat > "$WS/beta.md" <<'EOF'
# beta

> Second module description.
EOF
set +e
bash "$REF_DIR/update-docs-index.sh" "$WS" >/dev/null
rc=$?
set -e
assert_exit "two modules -> exit 0" 0 "$rc"
if [ -f "$WS/README.md" ] && grep -q "alpha" "$WS/README.md" && grep -q "beta" "$WS/README.md"; then
  echo -e "  ${GREEN}[PASS]${NC} README.md lists both modules"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} README.md missing module entries"
  fail=$((fail + 1))
fi

# ── run-tests.sh ─────────────────────────────────────────────────────────────
note "run-tests.sh"

# 1. Bad target -> exit 3 (path doesn't exist)
set +e
bash "$REF_DIR/run-tests.sh" "/path/does/not/exist/$$" 2>/dev/null
rc=$?
set -e
assert_exit "nonexistent target -> exit 3" 3 "$rc"

# 2. Unsupported stack -> exit 2 (empty workspace, no manifests)
WS="$CMP_TMPDIR/run-tests-none"; mkdir -p "$WS"
set +e
( cd "$WS" && bash "$REF_DIR/run-tests.sh" 2>/dev/null )
rc=$?
set -e
assert_exit "no manifests -> exit 2" 2 "$rc"

# 3. Python stack routes to pytest. Verify by stubbing `python` on PATH so the
#    helper invokes our recorder instead of the real interpreter. The recorder
#    captures argv and exits 0 — enough to confirm the routing without needing
#    pytest installed in the test env.
WS="$CMP_TMPDIR/run-tests-py"; mkdir -p "$WS"
touch "$WS/pyproject.toml"
BIN="$CMP_TMPDIR/run-tests-py-bin"; mkdir -p "$BIN"
cat > "$BIN/python" <<EOF
#!/usr/bin/env bash
echo "ARGS: \$*" > "$WS/captured.txt"
exit 0
EOF
chmod +x "$BIN/python"
set +e
( cd "$WS" && PATH="$BIN:$PATH" bash "$REF_DIR/run-tests.sh" "" "my_filter" >/dev/null 2>&1 )
rc=$?
set -e
assert_exit "python stack routes (exit 0 from stub)" 0 "$rc"
if [ -f "$WS/captured.txt" ] && grep -q -- "-m pytest" "$WS/captured.txt" && grep -q -- "-k my_filter" "$WS/captured.txt"; then
  echo -e "  ${GREEN}[PASS]${NC} python stack invoked pytest with -k filter"
  pass=$((pass + 1))
else
  echo -e "  ${RED}[FAIL]${NC} pytest invocation not captured as expected"
  [ -f "$WS/captured.txt" ] && cat "$WS/captured.txt" | awk '{print "      " $0}'
  fail=$((fail + 1))
fi

# ── Working-tree mutation guard ──────────────────────────────────────────────
note "Working-tree mutation guard"
if [ "$IN_GIT_REPO" = "1" ]; then
  CURRENT_SNAPSHOT="$(git -C "$REPO_ROOT" status --porcelain)"
  if [ "$WORKTREE_SNAPSHOT" = "$CURRENT_SNAPSHOT" ]; then
    echo -e "  ${GREEN}[PASS]${NC} repo working tree unchanged"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} repo working tree mutated by the test run"
    diff <(echo "$WORKTREE_SNAPSHOT") <(echo "$CURRENT_SNAPSHOT") | awk '{print "      " $0}'
    fail=$((fail + 1))
  fi
else
  echo -e "  ${BLUE}--${NC} not in a git repo; mutation guard skipped"
fi

echo ""
echo "============================================"
total=$((pass + fail))
if [ "$fail" -eq 0 ]; then
  echo -e "${GREEN}All ${total} reference self-tests passed.${NC}"
  exit 0
else
  echo -e "${RED}${fail} of ${total} reference self-tests failed.${NC}"
  exit 1
fi
