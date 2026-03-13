#!/usr/bin/env bash
# Hook: PreToolUse (Bash tool)
# Fires before every Bash tool call.
# Purpose: Safety guard + audit logging for all shell commands.
#
# Claude Code passes the command via CLAUDE_TOOL_INPUT_COMMAND env var.
# Exit code 0 = allow, non-zero = block.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Read the command Claude wants to run
COMMAND="${CLAUDE_TOOL_INPUT_COMMAND:-}"

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Audit log: record every command with timestamp
AUDIT_LOG=".claude/audit.log"
mkdir -p "$(dirname "$AUDIT_LOG")"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] BASH: $COMMAND" >> "$AUDIT_LOG"

# ── BLOCK LIST ──────────────────────────────────────────────────────────────
# These patterns are always blocked regardless of context.

BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm --no-preserve-root"
  ":(){:|:&};:"                # fork bomb
  "dd if=/dev/zero of=/dev/"  # disk wipe
  "mkfs\."                     # filesystem format
  "> /dev/sd"                  # raw disk write
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "git push --force.*main"
  "git push --force.*master"
  "git push -f.*main"
  "git push -f.*master"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo -e "${RED}[BLOCKED]${NC} Dangerous command pattern detected: '$pattern'"
    echo -e "${RED}Command:${NC} $COMMAND"
    echo ""
    echo "This command was blocked by the pre-tool-use safety hook."
    echo "If you genuinely need to run this, ask the user to do it manually."
    exit 1
  fi
done

# ── WARNING LIST ─────────────────────────────────────────────────────────────
# These patterns are allowed but trigger a visible warning.

WARN_PATTERNS=(
  "pip install"
  "pip3 install"
  "npm install"
  "npm ci"
  "curl.*|.*sh"    # curl-to-shell installs
  "wget.*|.*sh"
)

for pattern in "${WARN_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo -e "${YELLOW}[WARN]${NC} Package installation detected: review before running."
    echo -e "Command: $COMMAND"
    echo ""
    break
  fi
done

# ── SECRET LEAK CHECK ────────────────────────────────────────────────────────
# Warn if command appears to echo/print a token or secret

if echo "$COMMAND" | grep -qiE "echo.*(GITHUB_TOKEN|SENTRY_TOKEN|API_KEY|SECRET|PASSWORD)"; then
  echo -e "${YELLOW}[WARN]${NC} Command may expose a secret value. Verify this is intentional."
fi

exit 0
