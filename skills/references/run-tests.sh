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

# Python wins over node when both are present — the project's own examples are
# Python, and the prior hardcoded behaviour was always pytest. Order-stable so
# callers can reason about which runner fires on mixed projects.
case ",${STACK}," in
  *,python,*)
    cmd=(python -m pytest)
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
