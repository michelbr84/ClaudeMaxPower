#!/usr/bin/env bash
# Hook: SessionStart
# Fires when Claude Code begins a new session.
# Purpose: Orient Claude with project context before any work begins.

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  ClaudeMaxPower — Session Start${NC}"
echo -e "${BLUE}============================================${NC}"

# Date and time
echo ""
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"

# Git context
if git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  echo -e "Branch: ${GREEN}${BRANCH}${NC}"
  echo ""
  echo "Recent commits:"
  git log --oneline -5 2>/dev/null | sed 's/^/  /' || echo "  (no commits yet)"
else
  echo -e "${YELLOW}Not inside a git repository.${NC}"
fi

# Session state file
echo ""
if [ -f ".estado.md" ]; then
  echo -e "${GREEN}Previous session state found (.estado.md):${NC}"
  echo "---"
  cat .estado.md
  echo "---"
else
  echo "No previous session state (.estado.md not found). Starting fresh."
fi

# Environment check
echo ""
if [ -f ".env" ]; then
  echo -e "${GREEN}.env file found.${NC}"
  # Check for unfilled placeholders
  if grep -q "your_token_here\|your_sentry_auth_token\|your-org-slug\|your-username" .env 2>/dev/null; then
    echo -e "${YELLOW}Warning: .env has unfilled placeholder values. Update before using integrations.${NC}"
  fi
else
  echo -e "${YELLOW}Warning: .env not found. Run: bash scripts/setup.sh${NC}"
fi

# Available skills summary
echo ""
echo "Available skills (invoke with /skill-name):"
if [ -d "skills" ]; then
  for f in skills/*.md; do
    name=$(basename "$f" .md)
    echo "  /$name"
  done
else
  echo "  (skills/ directory not found)"
fi

# Auto Dream — background memory consolidation
if [ -f "scripts/auto-dream.sh" ]; then
  bash scripts/auto-dream.sh &>/dev/null &
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo ""
