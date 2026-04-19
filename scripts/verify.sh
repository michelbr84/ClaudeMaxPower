#!/usr/bin/env bash
# ClaudeMaxPower Verify Script
# Checks that all required tools are installed and configured correctly.
# Usage: bash scripts/verify.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()      { echo -e "${GREEN}[PASS]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[FAIL]${NC} $1"; FAILURES=$((FAILURES + 1)); }
section() { echo -e "\n${BLUE}--- $1 ---${NC}"; }

FAILURES=0

echo ""
echo "============================================"
echo "  ClaudeMaxPower — Verification"
echo "============================================"

# Required tools
section "Required Tools"
for tool in claude git gh jq python3; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool: $(command -v "$tool")"
  else
    fail "$tool: not found"
  fi
done

# Optional tools
section "Optional Tools"
for tool in dot shellcheck markdownlint; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool: available (enables extra features)"
  else
    warn "$tool: not found (optional — some features will be limited)"
  fi
done

# Environment file
section "Environment"
if [ -f ".env" ]; then
  ok ".env file exists"
  if grep -q "your_token_here\|your-username/your-repo" .env; then
    warn ".env has unfilled placeholder values — update before using integrations"
  else
    ok ".env appears to be configured"
  fi
else
  fail ".env not found — run: bash scripts/setup.sh"
fi

# Hook scripts
section "Hooks"
for hook in session-start pre-tool-use post-tool-use stop; do
  f=".claude/hooks/${hook}.sh"
  if [ -f "$f" ]; then
    if [ -x "$f" ]; then
      ok "$f: exists and is executable"
    else
      fail "$f: exists but not executable (run: chmod +x $f)"
    fi
  else
    fail "$f: not found"
  fi
done

# Skills
section "Skills"
for skill in fix-issue review-pr refactor-module tdd-loop pre-commit generate-docs; do
  f="skills/${skill}.md"
  if [ -f "$f" ]; then
    ok "$f: found"
  else
    fail "$f: not found"
  fi
done

# Agents
section "Agents"
for agent in code-reviewer security-auditor doc-writer; do
  f=".claude/agents/${agent}.md"
  if [ -f "$f" ]; then
    ok "$f: found"
  else
    fail "$f: not found"
  fi
done

# GitHub CLI auth
section "GitHub CLI"
if gh auth status &>/dev/null; then
  ok "gh: authenticated"
else
  warn "gh: not authenticated — run: gh auth login"
fi

# Python example tests
section "Example Tests"
if [ -d "examples/todo-app/tests" ]; then
  if python3 -m pytest examples/todo-app/tests -q --tb=short 2>/dev/null; then
    ok "todo-app tests: passing"
  else
    fail "todo-app tests: failing"
  fi
else
  warn "todo-app tests directory not found"
fi

# Summary
echo ""
echo "============================================"
if [ "$FAILURES" -eq 0 ]; then
  echo -e "${GREEN}All checks passed! ClaudeMaxPower is ready.${NC}"
else
  echo -e "${RED}$FAILURES check(s) failed. Review the output above.${NC}"
  exit 1
fi
echo "============================================"
echo ""
