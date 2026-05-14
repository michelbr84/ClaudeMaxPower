#!/usr/bin/env bash
# Deterministic pre-commit checks for ClaudeMaxPower.
#
# Wired into .claude/settings.json as a PreToolUse hook on Bash. The Bash matcher
# fires on every Bash invocation, so this script filters internally — it only acts
# when the command being run is `git commit`.
#
# Behaviour:
#   - Blocks (exit 1) on detected secrets in staged changes.
#   - Warns (exit 0 + stdout note) on debug statements, large files, linter issues.
#
# Replaces the deterministic portion of the old /pre-commit skill. The LLM portion
# (Conventional Commits message generation) lives in skills/gen-commit-message.md.

set -euo pipefail

# Claude Code passes the tool input through stdin as JSON or via env vars.
# We inspect both possibilities and exit 0 quietly if this is not a `git commit`.
TOOL_INPUT=""
if [ -t 0 ]; then
  TOOL_INPUT=""
else
  TOOL_INPUT="$(cat 2>/dev/null || true)"
fi

# Pull the command out of either the JSON payload or the well-known env var.
CMD=""
if [ -n "${CLAUDE_TOOL_INPUT_COMMAND:-}" ]; then
  CMD="$CLAUDE_TOOL_INPUT_COMMAND"
elif [ -n "$TOOL_INPUT" ] && command -v jq >/dev/null 2>&1; then
  CMD="$(echo "$TOOL_INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || true)"
fi

# Only act on `git commit` invocations. Anything else: silent pass.
if ! echo "$CMD" | grep -qE '(^|[[:space:]])git[[:space:]]+commit($|[[:space:]])'; then
  exit 0
fi

# We are about to commit. Run the checks against staged content.

# Bail fast if there's nothing staged — let git's own "nothing to commit" handle it.
if ! git diff --staged --quiet 2>/dev/null; then
  : # there are staged changes, continue
else
  exit 0
fi

FAILED=0

# --- Check 1: secret / credential leak detection (BLOCKING) ---
SECRETS="$(git diff --staged \
  | grep -iE '^\+.*(api[_-]?key|secret|password|passwd|token|private[_-]?key|credentials)[[:space:]]*[:=]' \
  | grep -viE '(example|placeholder|your[_-]?token|^\+\+\+|^\+#|//|TODO|FIXME)' \
  || true)"

if [ -n "$SECRETS" ]; then
  echo "" >&2
  echo "[pre-commit-check] BLOCKED: possible secret in staged changes." >&2
  echo "$SECRETS" | head -n 10 >&2
  echo "" >&2
  echo "Remove the secret, then re-stage and re-attempt the commit." >&2
  FAILED=1
fi

# --- Check 2: debug-statement detection (WARN ONLY) ---
DEBUG_HITS="$(git diff --staged \
  | grep -E '^\+.*(console\.log|print\(|debugger|pdb\.set_trace|breakpoint\(\)|TODO: REMOVE|FIXME: REMOVE)' \
  || true)"

if [ -n "$DEBUG_HITS" ]; then
  echo "" >&2
  echo "[pre-commit-check] WARNING: debug statements detected in staged changes:" >&2
  echo "$DEBUG_HITS" | head -n 5 >&2
  echo "(continuing — confirm these are intentional)" >&2
fi

# --- Check 3: large-file warning (WARN ONLY) ---
LARGE=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  SIZE=$(wc -c < "$f" 2>/dev/null || echo 0)
  if [ "$SIZE" -gt 1048576 ]; then
    LARGE="${LARGE}${f} (${SIZE} bytes)\n"
  fi
done < <(git diff --staged --name-only 2>/dev/null)

if [ -n "$LARGE" ]; then
  echo "" >&2
  echo "[pre-commit-check] WARNING: staged file(s) over 1MB:" >&2
  printf "%b" "$LARGE" >&2
fi

# --- Check 4: linter (WARN ONLY) ---
STAGED_PY="$(git diff --staged --name-only 2>/dev/null | grep '\.py$' || true)"
if [ -n "$STAGED_PY" ] && command -v flake8 >/dev/null 2>&1; then
  if ! echo "$STAGED_PY" | xargs flake8 --max-line-length=100 >&2 2>&1; then
    echo "[pre-commit-check] WARNING: flake8 reported issues (continuing)." >&2
  fi
fi

STAGED_JS="$(git diff --staged --name-only 2>/dev/null | grep -E '\.(js|jsx|ts|tsx)$' || true)"
if [ -n "$STAGED_JS" ] && command -v npx >/dev/null 2>&1; then
  if ! echo "$STAGED_JS" | xargs npx --no-install eslint >&2 2>&1; then
    echo "[pre-commit-check] WARNING: eslint reported issues (continuing)." >&2
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi

exit 0
