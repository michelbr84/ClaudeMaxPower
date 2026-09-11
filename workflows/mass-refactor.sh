#!/usr/bin/env bash
# mass-refactor.sh — Batch refactoring across multiple files using Claude headless mode
#
# Usage: ./workflows/mass-refactor.sh --pattern <grep-pattern> --goal <refactor-description> [--dir <directory>]
# Example: ./workflows/mass-refactor.sh --pattern "get_user_by_id" --goal "rename to fetch_user and add error handling"
#
# Workflow:
#   1. grep finds all files matching the pattern
#   2. For each file: claude -p applies the refactor
#   3. git diff summary at the end

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
fi

PATTERN=""
GOAL=""
SEARCH_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pattern) PATTERN="$2"; shift 2 ;;
    --goal)    GOAL="$2";    shift 2 ;;
    --dir)     SEARCH_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [ -z "$PATTERN" ] || [ -z "$GOAL" ]; then
  echo "Usage: $0 --pattern <pattern> --goal <description> [--dir <dir>]"
  exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ClaudeMaxPower — Mass Refactor${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Pattern: $PATTERN"
echo "Goal: $GOAL"
echo "Directory: $SEARCH_DIR"
echo ""

# Step 1: Find all matching files
echo "Searching for files matching: $PATTERN"
MATCHING_FILES=$(grep -rl "$PATTERN" "$SEARCH_DIR" \
  --include="*.py" --include="*.js" --include="*.ts" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="__pycache__" \
  2>/dev/null || true)

if [ -z "$MATCHING_FILES" ]; then
  echo -e "${YELLOW}No files found matching pattern: $PATTERN${NC}"
  exit 0
fi

FILE_COUNT=$(echo "$MATCHING_FILES" | wc -l)
echo -e "${GREEN}Found $FILE_COUNT file(s):${NC}"
echo "  ${MATCHING_FILES//$'\n'/$'\n  '}"
echo ""

# Safety check for large refactors
if [ "$FILE_COUNT" -gt 20 ]; then
  echo -e "${YELLOW}Warning: $FILE_COUNT files is a large refactor.${NC}"
  echo "Continue? (y/N)"
  read -r CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0
fi

# Step 2: Refactor each file
PASSED=0
FAILED=0

while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  echo -e "${BLUE}Refactoring: $FILE${NC}"

  PROMPT="Refactor the file at path: $FILE

Goal: $GOAL

Instructions:
- Read the entire file first
- Apply the refactor minimally — only change what's needed for the goal
- Do not change unrelated code
- After refactoring, if a test file exists for this file, run the tests to verify nothing broke
- Report: what changed and test results"

  if claude --print \
    --allowedTools "Bash,Read,Edit,Glob,Grep" \
    "$PROMPT" 2>&1; then
    echo -e "${GREEN}[OK]${NC} $FILE"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}[FAIL]${NC} $FILE"
    FAILED=$((FAILED + 1))
  fi
  echo ""

done <<< "$MATCHING_FILES"

# Step 3: Show git diff summary
echo ""
echo -e "${BLUE}Git diff summary:${NC}"
git diff --stat 2>/dev/null || echo "(not a git repo or no changes)"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "Mass refactor complete: ${GREEN}$PASSED ok${NC}, ${RED}$FAILED failed${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

[ "$FAILED" -eq 0 ] || exit 1
