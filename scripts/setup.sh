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

# On Git Bash / MSYS / Cygwin, the bash inherits a limited PATH from cmd.exe
# that often omits user-level and Program Files tool installs. Augment PATH
# with the common Windows install locations so command -v can find .exe tools.
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    WIN_USER="${USERNAME:-${USER:-}}"
    EXTRA_PATHS=(
      "/c/Program Files/GitHub CLI"
      "/c/Program Files (x86)/GitHub CLI"
      "/c/Program Files/jq"
      "/usr/local/bin"
      "/mingw64/bin"
    )
    if [ -n "$WIN_USER" ]; then
      EXTRA_PATHS+=(
        "/c/Users/$WIN_USER/.local/bin"
        "/c/Users/$WIN_USER/AppData/Local/Programs/claude/bin"
        "/c/Users/$WIN_USER/AppData/Local/Microsoft/WinGet/Links"
      )
    fi
    for p in "${EXTRA_PATHS[@]}"; do
      [ -d "$p" ] && PATH="$PATH:$p"
    done
    export PATH
    ;;
esac

# 1. Check required tools
echo "Checking required tools..."

MISSING=0

# On Windows, many CLIs are shipped as .exe. Try both the bare name and the
# .exe variant before giving up.
find_tool() {
  local tool=$1
  if command -v "$tool" &>/dev/null; then
    command -v "$tool"
    return 0
  fi
  if command -v "$tool.exe" &>/dev/null; then
    command -v "$tool.exe"
    return 0
  fi
  return 1
}

check_tool() {
  local tool=$1
  local install_hint=$2
  local found
  if found=$(find_tool "$tool"); then
    ok "$tool found ($found)"
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

# 4b. Generate Claude Code slash-command wrappers from skills/*.md
# Claude Code auto-discovers slash commands from .claude/commands/<name>.md.
# The wrappers delegate to the canonical skill files in skills/.
if [ -f "scripts/generate-commands.py" ] && [ -d "skills" ]; then
  echo ""
  echo "Generating Claude Code slash-command wrappers..."
  if python3 scripts/generate-commands.py >/dev/null; then
    ok "Slash commands generated in .claude/commands/ (restart Claude Code to pick them up)."
  else
    warn "Failed to generate slash-command wrappers. Run: python3 scripts/generate-commands.py"
  fi
fi

# 5. Install Python dependencies for the todo-app example into a local venv.
# Using a venv avoids PEP 668 "externally-managed-environment" errors on
# Debian/Ubuntu/WSL and keeps example deps isolated from the system Python.
if [ -f "examples/todo-app/requirements.txt" ]; then
  echo ""
  echo "Installing Python dependencies for todo-app example..."
  VENV_DIR="examples/todo-app/.venv"
  VENV_STAMP="$VENV_DIR/.requirements.sha256"
  REQ_FILE="examples/todo-app/requirements.txt"

  if [ ! -d "$VENV_DIR" ]; then
    if ! python3 -m venv "$VENV_DIR" 2>/tmp/cmp-venv-err; then
      warn "python3 -m venv failed: $(head -1 /tmp/cmp-venv-err 2>/dev/null)"
      warn "On Debian/Ubuntu/WSL run:  sudo apt install -y python3-venv python3-full"
      warn "Skipping example dependencies — re-run scripts/setup.sh after installing."
      VENV_DIR=""
    fi
    rm -f /tmp/cmp-venv-err
  fi

  if [ -n "$VENV_DIR" ]; then
    # Handle both Unix (bin/python) and Windows (Scripts/python.exe) venv layouts.
    if   [ -x "$VENV_DIR/bin/python" ];         then VENV_PY="$VENV_DIR/bin/python"
    elif [ -x "$VENV_DIR/Scripts/python.exe" ]; then VENV_PY="$VENV_DIR/Scripts/python.exe"
    else VENV_PY=""
    fi

    if [ -z "$VENV_PY" ]; then
      warn "Could not locate python inside $VENV_DIR. Skipping dependency install."
    else
      # Skip reinstall when requirements haven't changed (idempotent).
      REQ_HASH="$(sha256sum "$REQ_FILE" | awk '{print $1}')"
      if [ -f "$VENV_STAMP" ] && [ "$(cat "$VENV_STAMP" 2>/dev/null)" = "$REQ_HASH" ]; then
        ok "Python dependencies already up to date in $VENV_DIR"
      elif "$VENV_PY" -m pip install -r "$REQ_FILE" -q --disable-pip-version-check; then
        echo "$REQ_HASH" > "$VENV_STAMP"
        ok "Python dependencies installed in $VENV_DIR"
        echo "  Activate with:  source $VENV_DIR/bin/activate"
        echo "     (Windows:     source $VENV_DIR/Scripts/activate)"
      else
        warn "pip install failed. Try manually: $VENV_PY -m pip install -r $REQ_FILE"
      fi
    fi
  fi
fi

# 6. Check gh auth
echo ""
echo "Checking GitHub CLI authentication..."
GH_BIN="$(find_tool gh || true)"
if [ -n "$GH_BIN" ] && "$GH_BIN" auth status &>/dev/null; then
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
