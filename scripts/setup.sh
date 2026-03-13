#!/usr/bin/env bash
# ClaudeMaxPower Setup Script
# Run once after cloning: bash scripts/setup.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "============================================"
echo "  ClaudeMaxPower — Setup"
echo "============================================"
echo ""

# 1. Check required tools
echo "Checking required tools..."

MISSING=0

check_tool() {
  local tool=$1
  local install_hint=$2
  if command -v "$tool" &>/dev/null; then
    ok "$tool found ($(command -v "$tool"))"
  else
    err "$tool not found. $install_hint"
    MISSING=$((MISSING + 1))
  fi
}

check_tool "claude"  "Install Claude Code: https://claude.ai/code"
check_tool "git"     "Install git: https://git-scm.com"
check_tool "gh"      "Install GitHub CLI: https://cli.github.com"
check_tool "jq"      "Install jq: https://stedolan.github.io/jq/"
check_tool "python3" "Install Python 3: https://python.org"

echo ""

if [ "$MISSING" -gt 0 ]; then
  err "$MISSING required tool(s) missing. Please install them before continuing."
  exit 1
fi

# 2. Create .env if it doesn't exist
if [ ! -f ".env" ]; then
  cp .env.example .env
  warn ".env created from .env.example — fill in your values before using skills and MCP integrations."
else
  ok ".env already exists."
fi

# 3. Make hook scripts executable
echo ""
echo "Making hook scripts executable..."
chmod +x .claude/hooks/*.sh
ok "Hooks are executable."

# 4. Make workflow scripts executable
echo ""
echo "Making workflow scripts executable..."
chmod +x workflows/*.sh
chmod +x scripts/*.sh
ok "Workflow scripts are executable."

# 5. Install Python dependencies for examples
if [ -f "examples/todo-app/requirements.txt" ]; then
  echo ""
  echo "Installing Python dependencies for todo-app example..."
  python3 -m pip install -r examples/todo-app/requirements.txt -q
  ok "Python dependencies installed."
fi

# 6. Check gh auth
echo ""
echo "Checking GitHub CLI authentication..."
if gh auth status &>/dev/null; then
  ok "GitHub CLI is authenticated."
else
  warn "GitHub CLI is not authenticated. Run: gh auth login"
fi

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Edit .env and fill in your tokens"
echo "  2. Open Claude Code in this directory"
echo "  3. Try a skill: /fix-issue --issue 1 --repo owner/repo"
echo "  4. Read the docs: docs/getting-started.md"
echo ""
