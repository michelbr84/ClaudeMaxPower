#!/usr/bin/env bash
# Run the project's test suite, picking the runner from detect-stack.sh.
# Shared by /fix-issue (Steps 4 + 6) and /refactor-module (Steps 3 + 6) so
# the choice of "python -m pytest" vs "npm test" stops being hardcoded in
# the skill bodies (where it was wrong for non-Python projects).
#
# Usage:
#   bash skills/references/run-tests.sh [target] [filter]
#
#   target  Optional. Single file or directory to scope the run.
#   filter  Optional. Test-name substring filter (translated per runner).
#
# Output:
#   The invoked command is printed to stderr prefixed with "+" so callers
#   (and reviewers) can see exactly what ran. Test output streams straight
#   through on stdout/stderr — pipe or tee from the caller if needed.
#
# Exit codes:
#   0   — tests passed
#   1   — tests failed (or runner returned non-zero)
#   2   — stack not supported by this helper (run tests manually)
#   3   — bad input (target path does not exist)

set -euo pipefail

TARGET="${1:-}"
FILTER="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "$TARGET" ] && [ ! -e "$TARGET" ]; then
  echo "[run-tests] target does not exist: $TARGET" >&2
  exit 3
fi

STACK="$(bash "$SCRIPT_DIR/detect-stack.sh" . 2>/dev/null || echo "none")"

# Resolve the Python interpreter: project venv wins (it has the project's
# dependencies), then python3 (bare `python` is absent on many systems),
# then python as a last resort. Relative venv paths execute against cwd,
# which is the project root detect-stack.sh also probes.
resolve_py() {
  if [ -x ".venv/bin/python" ]; then
    echo ".venv/bin/python"
    return 0
  fi
  if [ -x ".venv/Scripts/python.exe" ]; then
    echo ".venv/Scripts/python.exe"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    echo "python"
    return 0
  fi
  return 1
}

# Python wins over node when both are present — the project's own examples are
# Python, and the prior hardcoded behaviour was always pytest. Order-stable so
# callers can reason about which runner fires on mixed projects.
case ",${STACK}," in
  *,python,*)
    if ! PY_BIN="$(resolve_py)"; then
      echo "[run-tests] python project detected, but no python interpreter found." >&2
      exit 2
    fi
    cmd=("$PY_BIN" -m pytest)
    [ -n "$TARGET" ] && cmd+=("$TARGET")
    cmd+=(-v --tb=short)
    [ -n "$FILTER" ] && cmd+=(-k "$FILTER")
    echo "+ ${cmd[*]}" >&2
    exec "${cmd[@]}"
    ;;
  *,node,*)
    if [ -n "$TARGET" ] || [ -n "$FILTER" ]; then
      echo "[run-tests] node detected; target/filter are not wired for npm test — running the full suite." >&2
    fi
    echo "+ npm test --if-present" >&2
    exec npm test --if-present
    ;;
  *)
    echo "[run-tests] stack '$STACK' is not yet supported by this helper." >&2
    echo "[run-tests] Supported: python, node. Run tests manually for now." >&2
    exit 2
    ;;
esac
