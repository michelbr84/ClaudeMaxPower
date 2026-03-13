#!/usr/bin/env bash
# Hook: PostToolUse (Edit, Write tools)
# Fires after every file edit or write.
# Purpose: Automated quality gate — run tests after code changes.
#
# Claude Code passes the file path via CLAUDE_TOOL_OUTPUT_FILE_PATH env var.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FILE_PATH="${CLAUDE_TOOL_OUTPUT_FILE_PATH:-}"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only act on source files (skip docs, configs, markdown)
case "$FILE_PATH" in
  *.py)
    ;;
  *.js|*.ts|*.jsx|*.tsx)
    ;;
  *)
    exit 0
    ;;
esac

echo ""
echo "[post-tool-use] File changed: $FILE_PATH"

# ── PYTHON ───────────────────────────────────────────────────────────────────
if [[ "$FILE_PATH" == *.py ]]; then
  # Find the nearest tests/ directory
  DIR=$(dirname "$FILE_PATH")
  TEST_DIR=""

  # Search upward for tests/ directory (max 3 levels)
  for _ in 1 2 3; do
    if [ -d "$DIR/tests" ]; then
      TEST_DIR="$DIR/tests"
      break
    fi
    DIR=$(dirname "$DIR")
  done

  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    echo "Running tests: python -m pytest $TEST_DIR -q --tb=short"
    if python3 -m pytest "$TEST_DIR" -q --tb=short 2>&1; then
      echo -e "${GREEN}[PASS]${NC} All tests passed."
    else
      echo -e "${RED}[FAIL]${NC} Tests failed after editing $FILE_PATH"
      echo "Fix the failing tests before proceeding."
    fi
  else
    echo -e "${YELLOW}[SKIP]${NC} No tests/ directory found near $FILE_PATH"
  fi
fi

# ── JAVASCRIPT / TYPESCRIPT ───────────────────────────────────────────────────
if [[ "$FILE_PATH" == *.js || "$FILE_PATH" == *.ts || "$FILE_PATH" == *.jsx || "$FILE_PATH" == *.tsx ]]; then
  # Find the nearest package.json
  DIR=$(dirname "$FILE_PATH")
  PKG=""

  for _ in 1 2 3; do
    if [ -f "$DIR/package.json" ]; then
      PKG="$DIR/package.json"
      break
    fi
    DIR=$(dirname "$DIR")
  done

  if [ -n "$PKG" ]; then
    echo "Running: npm test --if-present (in $(dirname "$PKG"))"
    cd "$(dirname "$PKG")"
    if npm test --if-present 2>&1; then
      echo -e "${GREEN}[PASS]${NC} All tests passed."
    else
      echo -e "${RED}[FAIL]${NC} Tests failed after editing $FILE_PATH"
    fi
  else
    echo -e "${YELLOW}[SKIP]${NC} No package.json found near $FILE_PATH"
  fi
fi

echo ""
