#!/usr/bin/env bash
# Detect whether ClaudeMaxPower is installed in the given directory.
# Used by /max-power Step 1.2.
#
# Usage: bash skills/references/detect-cmp-installation.sh [directory]
#
# Output (stdout): "yes" or "no"
# Exit codes: 0 always (status is communicated via stdout, not exit code)
#
# CMP is considered installed when ALL THREE markers are present:
#   1. .claude/hooks/session-start.sh exists
#   2. skills/assemble-team.md exists
#   3. CLAUDE.md exists AND contains the string "ClaudeMaxPower"

set -euo pipefail

DIR="${1:-.}"

if [ ! -f "$DIR/.claude/hooks/session-start.sh" ]; then
  echo "no"
  exit 0
fi

if [ ! -f "$DIR/skills/assemble-team.md" ]; then
  echo "no"
  exit 0
fi

if [ ! -f "$DIR/CLAUDE.md" ] || ! grep -q "ClaudeMaxPower" "$DIR/CLAUDE.md"; then
  echo "no"
  exit 0
fi

echo "yes"
