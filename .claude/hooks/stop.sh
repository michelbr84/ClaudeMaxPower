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

# Skip empty summaries entirely. Writing a placeholder on every session end
# accumulates noise (89 such entries in this repo's history) that session-start.sh
# then loads back into context. A session with nothing to record is fine.
if [ -z "$SUMMARY" ]; then
  echo -e "${YELLOW}[stop hook] No summary provided — skipping write to $ESTADO_FILE.${NC}"
  exit 0
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

# Note: .estado.md is intentionally NOT staged for git. It is gitignored
# (.estado*.md) as a local-only scratch file — session state stays on the
# machine that produced it instead of leaking into every clone/PR diff.

echo ""
