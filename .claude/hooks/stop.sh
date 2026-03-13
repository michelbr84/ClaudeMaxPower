#!/usr/bin/env bash
# Hook: Stop
# Fires when the Claude Code session ends.
# Purpose: Persist session state to .estado.md for the next session.

set -euo pipefail

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ESTADO_FILE=".estado.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo "[stop hook] Saving session state to $ESTADO_FILE..."

# Build the session summary
# Claude Code will have already written a summary to CLAUDE_STOP_HOOK_SUMMARY if available
SUMMARY="${CLAUDE_STOP_HOOK_SUMMARY:-}"

if [ -z "$SUMMARY" ]; then
  SUMMARY="Session ended at $TIMESTAMP. No summary provided."
fi

# Prepend new entry (most recent first)
ENTRY="## Session: $TIMESTAMP

$SUMMARY

---
"

if [ -f "$ESTADO_FILE" ]; then
  # Prepend to existing file
  EXISTING=$(cat "$ESTADO_FILE")
  printf '%s\n%s' "$ENTRY" "$EXISTING" > "$ESTADO_FILE"
else
  # Create new file
  printf '# Session State Log\n\n%s' "$ENTRY" > "$ESTADO_FILE"
fi

echo -e "${GREEN}Session state saved to $ESTADO_FILE${NC}"

# If inside a git repo, stage the state file
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  if git diff --name-only "$ESTADO_FILE" 2>/dev/null | grep -q "$ESTADO_FILE" || \
     ! git ls-files --error-unmatch "$ESTADO_FILE" &>/dev/null 2>&1; then
    git add "$ESTADO_FILE" 2>/dev/null || true
    echo -e "${YELLOW}Staged $ESTADO_FILE (not committed — commit manually when ready)${NC}"
  fi
fi

echo ""
