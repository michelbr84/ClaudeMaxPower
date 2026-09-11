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
#
# One failing item does not abort the batch: claude errors and unparseable
# output are recorded as failed entries, matching the per-item failure
# tolerance documented in docs/batch-workflows.md.

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "Usage: bash run.sh <owner/repo>"
  exit 1
fi

ISSUES_FILE="$(dirname "$0")/issues.txt"
RESULTS_FILE="$(dirname "$0")/batch-results.json"
SKILLS_DIR="$(dirname "$0")/../../skills"

# Load environment — no eval, no word splitting. .env is KEY=VALUE lines
# (optional "export " prefix, optional surrounding quotes); malformed lines
# are skipped, matching the loader the /fix-issue and /review-pr skills use.
ROOT="$(dirname "$0")/../.."
if [ -f "$ROOT/.env" ]; then
  while IFS= read -r env_line || [ -n "$env_line" ]; do
    env_line="${env_line%$'\r'}"
    env_line="${env_line#export }"
    case "$env_line" in ''|\#*) continue ;; esac
    env_key="${env_line%%=*}"
    env_value="${env_line#*=}"
    case "$env_key" in *[!A-Za-z0-9_]*|"") continue ;; esac
    case "$env_value" in
      \"*\") env_value="${env_value#\"}"; env_value="${env_value%\"}" ;;
      \'*\') env_value="${env_value#\'}"; env_value="${env_value%\'}" ;;
    esac
    export "$env_key=$env_value"
  done < "$ROOT/.env"
fi

echo "========================================"
echo "  ClaudeMaxPower — Batch Issue Fix Demo"
echo "========================================"
echo "Repository: $REPO"
echo "Issues file: $ISSUES_FILE"
echo ""

# Initialize results atomically: write to a temp file and mv at the end, so an
# interrupted run never leaves a truncated batch-results.json behind.
RESULTS_TMP="$RESULTS_FILE.tmp"
echo "[]" > "$RESULTS_TMP"

# Process each issue
while IFS= read -r line || [ -n "$line" ]; do
  # Skip comments and empty lines
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

  ISSUE_NUM="$line"
  echo "Processing issue #$ISSUE_NUM..."

  RESULT=$(claude --print \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
    --output-format json \
    "Using the fix-issue workflow from $SKILLS_DIR/fix-issue.md, fix GitHub issue #$ISSUE_NUM in repo $REPO. Follow all steps in the skill definition." \
    2>/dev/null || echo '{"error": "claude command failed"}')

  # Record the entry. Guard the parse so one bad result doesn't abort the
  # whole batch (set -e), and pass it via --argjson instead of interpolating
  # it into the jq program string.
  if ! ENTRY=$(echo "$RESULT" | jq -c \
    --arg issue "$ISSUE_NUM" \
    --arg repo "$REPO" \
    '{issue: $issue, repo: $repo, result: .}'); then
    ENTRY=$(jq -cn --arg issue "$ISSUE_NUM" --arg repo "$REPO" \
      '{issue: $issue, repo: $repo, result: {error: "unparseable claude output"}}')
  fi

  CURRENT=$(cat "$RESULTS_TMP")
  if ! NEW=$(printf '%s\n' "$CURRENT" | jq --argjson entry "$ENTRY" '. + [$entry]'); then
    echo "  WARN: could not append result for issue #$ISSUE_NUM; keeping previous results"
    continue
  fi
  printf '%s\n' "$NEW" > "$RESULTS_TMP"

  echo "  Done. Result appended to batch-results.json"
  echo ""

done < "$ISSUES_FILE"

mv "$RESULTS_TMP" "$RESULTS_FILE"

echo "========================================"
echo "  Batch complete!"
echo "  Results: $RESULTS_FILE"
echo "========================================"
echo ""

# Print summary
echo "Summary:"
jq -r '.[] | "  Issue #\(.issue): \(if .result.error then "FAILED - \(.result.error)" else "OK" end)"' \
  "$RESULTS_FILE" 2>/dev/null || echo "  (could not parse results)"