#!/usr/bin/env bash
# Batch Demo — fix multiple GitHub issues autonomously using Claude headless mode
#
# Usage: bash run.sh <owner/repo>
# Example: bash run.sh myuser/ClaudeMaxPower
#
# This script demonstrates the batch-fix workflow pattern:
# - Reads issue numbers from issues.txt
# - For each issue: runs claude -p to invoke the fix-issue workflow
# - Collects results in batch-results.json

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "Usage: bash run.sh <owner/repo>"
  exit 1
fi

ISSUES_FILE="$(dirname "$0")/issues.txt"
RESULTS_FILE="$(dirname "$0")/batch-results.json"
SKILLS_DIR="$(dirname "$0")/../../skills"

# Load environment
ROOT="$(dirname "$0")/../.."
[ -f "$ROOT/.env" ] && export $(grep -v '^#' "$ROOT/.env" | xargs)

echo "========================================"
echo "  ClaudeMaxPower — Batch Issue Fix Demo"
echo "========================================"
echo "Repository: $REPO"
echo "Issues file: $ISSUES_FILE"
echo ""

# Initialize results file
echo "[]" > "$RESULTS_FILE"

# Process each issue
while IFS= read -r line; do
  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

  ISSUE_NUM="$line"
  echo "Processing issue #$ISSUE_NUM..."

  RESULT=$(claude --print \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
    --output-format json \
    "Using the fix-issue workflow from $SKILLS_DIR/fix-issue.md, fix GitHub issue #$ISSUE_NUM in repo $REPO. Follow all steps in the skill definition." \
    2>/dev/null || echo '{"error": "claude command failed"}')

  # Append to results
  ENTRY=$(echo "$RESULT" | jq -c \
    --arg issue "$ISSUE_NUM" \
    --arg repo "$REPO" \
    '{issue: $issue, repo: $repo, result: .}')

  CURRENT=$(cat "$RESULTS_FILE")
  echo "$CURRENT" | jq ". + [$ENTRY]" > "$RESULTS_FILE"

  echo "  Done. Result appended to batch-results.json"
  echo ""

done < "$ISSUES_FILE"

echo "========================================"
echo "  Batch complete!"
echo "  Results: $RESULTS_FILE"
echo "========================================"
echo ""

# Print summary
echo "Summary:"
jq -r '.[] | "  Issue #\(.issue): \(if .result.error then "FAILED - \(.result.error)" else "OK" end)"' \
  "$RESULTS_FILE" 2>/dev/null || echo "  (could not parse results)"
