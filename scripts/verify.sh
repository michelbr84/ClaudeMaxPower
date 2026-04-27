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
info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
fail()    { echo -e "${RED}[FAIL]${NC} $1"; FAILURES=$((FAILURES + 1)); }
section() { echo -e "\n${BLUE}--- $1 ---${NC}"; }

FAILURES=0
STRICT_EXAMPLES="${VERIFY_STRICT_EXAMPLES:-0}"

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
# NOTE: examples/todo-app ships with 3 INTENTIONAL bugs as fixtures for the
# /fix-issue, /tdd-loop, and /pre-commit skill demos. By default, failures here
# are informational and do NOT count against installation verification.
# Set VERIFY_STRICT_EXAMPLES=1 to treat them as hard failures (legacy behaviour).
section "Example App (intentional bugs — informational)"
if [ -d "examples/todo-app/tests" ]; then
  echo -e "${YELLOW}ℹ${NC} examples/todo-app contains 3 intentional bugs used to demonstrate"
  echo -e "${YELLOW}ℹ${NC} the /fix-issue, /tdd-loop, and /pre-commit skills."
  echo -e "${YELLOW}ℹ${NC} See examples/todo-app/README.md and examples/todo-app/CLAUDE.md."

  if python3 -m pytest examples/todo-app/tests -q --tb=line 2>/dev/null; then
    ok "todo-app tests: all passing (bugs may have been fixed already)"
  else
    if [ "$STRICT_EXAMPLES" = "1" ]; then
      fail "todo-app tests: failing (VERIFY_STRICT_EXAMPLES=1 — counted as failure)"
    else
      info "todo-app tests: failing as expected (3 seeded bugs — pedagogical fixture)"
      info "to treat these as hard failures, run: VERIFY_STRICT_EXAMPLES=1 bash scripts/verify.sh"
    fi
  fi
else
  warn "todo-app tests directory not found"
fi

# Summary
echo ""
echo "============================================"
if [ "$FAILURES" -eq 0 ]; then
  echo -e "${GREEN}All infrastructure checks passed! ClaudeMaxPower is ready.${NC}"
  if [ "$STRICT_EXAMPLES" != "1" ]; then
    echo -e "${YELLOW}(Example-app tests are informational by default; set VERIFY_STRICT_EXAMPLES=1 to enforce.)${NC}"
  fi
else
  echo -e "${RED}$FAILURES infrastructure check(s) failed. Review the output above.${NC}"
  exit 1
fi
echo "============================================"
echo ""
