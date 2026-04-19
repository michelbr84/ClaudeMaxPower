#!/usr/bin/env bash
# batch-fix.sh — Fix multiple GitHub issues autonomously using Claude headless mode
#
# Usage: ./workflows/batch-fix.sh <owner/repo> <issue1> [issue2] [issue3] ...
# Example: ./workflows/batch-fix.sh myuser/myrepo 10 11 12
#
# For each issue:
#   1. Invokes Claude in headless mode (-p / --print)
#   2. Uses the fix-issue skill workflow
#   3. Logs results to batch-results.json

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load env
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env
  set +a
fi

REPO="${1:-}"
shift || true
ISSUES=("$@")

if [ -z "$REPO" ] || [ "${#ISSUES[@]}" -eq 0 ]; then
  echo "Usage: $0 <owner/repo> <issue1> [issue2] ..."
  exit 1
fi

RESULTS_FILE="batch-results.json"
SKILL_FILE="skills/fix-issue.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo -e "${RED}Error:${NC} $SKILL_FILE not found. Run from project root."
  exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ClaudeMaxPower — Batch Issue Fix${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Repository: $REPO"
echo "Issues: ${ISSUES[*]}"
echo "Results: $RESULTS_FILE"
echo ""

# Initialize results
echo "[]" > "$RESULTS_FILE"

PASSED=0
FAILED=0

for ISSUE in "${ISSUES[@]}"; do
  echo -e "${BLUE}--- Issue #$ISSUE ---${NC}"

  PROMPT="You are fixing GitHub issue #$ISSUE in repository $REPO.
Follow the workflow defined in $SKILL_FILE exactly.
Issue number: $ISSUE
Repository: $REPO"

  START=$(date +%s)

  if OUTPUT=$(claude --print \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
    --output-format json \
    "$PROMPT" 2>&1); then
    STATUS="success"
    PASSED=$((PASSED + 1))
    echo -e "${GREEN}[OK]${NC} Issue #$ISSUE processed successfully."
  else
    STATUS="error"
    FAILED=$((FAILED + 1))
    echo -e "${RED}[FAIL]${NC} Issue #$ISSUE failed."
  fi

  END=$(date +%s)
  DURATION=$((END - START))

  # Append result to JSON
  ENTRY=$(jq -n \
    --arg issue "$ISSUE" \
    --arg repo "$REPO" \
    --arg status "$STATUS" \
    --arg duration "${DURATION}s" \
    --arg output "$OUTPUT" \
    '{issue: $issue, repo: $repo, status: $status, duration: $duration, output: $output}')

  CURRENT=$(cat "$RESULTS_FILE")
  echo "$CURRENT" | jq ". + [$ENTRY]" > "$RESULTS_FILE"

  echo ""
done

echo -e "${BLUE}========================================${NC}"
echo -e "Batch complete: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo -e "Full results: $RESULTS_FILE"
echo -e "${BLUE}========================================${NC}"
echo ""

[ "$FAILED" -eq 0 ] || exit 1
