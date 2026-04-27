#!/usr/bin/env bash
# verify-ci.sh — Run the same checks CI runs, locally, with pinned tool versions.
#
# Usage:    bash scripts/verify-ci.sh
# From:     repository root
#
# Mirrors the gating jobs in .github/workflows/ci.yml:
#   1. Validate Shell Scripts        (shellcheck v0.10.0)
#   2. Validate GitHub Actions       (actionlint v1.7.7)
#   3. Validate JSON Files           (jq)
#   4. Check for Secrets             (grep)
#   5. Verify Project Structure      (test -f)
#
# Also mirrored when the local toolchain is present:
#   6. Lint Markdown                 (markdownlint-cli; informational in CI — `|| true`)
#   7. Run Example Tests             (pytest; informational + gating collection check)
#
# When 6 or 7 cannot run (markdownlint missing, or examples/todo-app/.venv not
# created yet), the script prints an explicit SKIPPED line. Skipped checks are
# never silently omitted, so a green local run is honest about what it covered.
# To bring a skipped check online, install the missing tool or run
# `bash scripts/setup.sh` to create the venv, then re-run this script.
#
# The shellcheck and actionlint binaries are downloaded once to
# ${XDG_CACHE_HOME:-$HOME/.cache}/cmp-verify/bin and re-used. Delete that
# directory to force a fresh download.
#
# Exit code: 0 if every gating check passes, 1 if any gating check failed.
# SKIPPED and INFO lines never affect the exit code.

set -euo pipefail

SHELLCHECK_VERSION="v0.10.0"
ACTIONLINT_VERSION="1.7.7"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cmp-verify"
BIN_DIR="$CACHE_DIR/bin"
mkdir -p "$BIN_DIR"

G='\033[0;32m'; R='\033[0;31m'; B='\033[0;34m'; Y='\033[1;33m'; D='\033[2m'; N='\033[0m'

PASSED=0
FAILED=0
SKIPPED=0
INFO=0
FAILS=()

ok()   { echo -e "  ${G}OK${N}    $1"; PASSED=$((PASSED + 1)); }
no()   { echo -e "  ${R}FAIL${N}  $1"; FAILED=$((FAILED + 1)); FAILS+=("$1"); }
# info() — non-gating signal. Mirrors CI checks that use `|| true` or
# `continue-on-error: true`. Counted separately so the user can see the local
# mirror saw the same output CI would, without affecting exit code.
info() { echo -e "  ${B}INFO${N}  $1"; INFO=$((INFO + 1)); }
# skip() — local toolchain is missing. Counted separately so a clean local run
# is never silently incomplete.
skip() { echo -e "  ${Y}SKIP${N}  $1"; SKIPPED=$((SKIPPED + 1)); }
sec()  { echo ""; echo -e "${B}== $1 ==${N}"; }

# --- Sanity: must run from repo root ---
if [ ! -f "CLAUDE.md" ] || [ ! -d ".github/workflows" ]; then
  echo "ERROR: run this from the ClaudeMaxPower repository root." >&2
  exit 1
fi

# --- Platform detection ---
case "$(uname -s)" in
  Linux*)               PLAT=linux ;;
  Darwin*)              PLAT=darwin ;;
  MINGW*|MSYS*|CYGWIN*) PLAT=windows ;;
  *)                    PLAT=unknown ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  ARCH=x86_64 ;;
  arm64|aarch64) ARCH=aarch64 ;;
  *)             ARCH=unknown ;;
esac

# --- Tool installers ---
ensure_shellcheck() {
  local exe="shellcheck"
  [ "$PLAT" = "windows" ] && exe="shellcheck.exe"
  SHELLCHECK_BIN="$BIN_DIR/$exe"
  if [ -x "$SHELLCHECK_BIN" ] && "$SHELLCHECK_BIN" --version 2>/dev/null | grep -q "${SHELLCHECK_VERSION#v}"; then
    return 0
  fi
  echo -e "${D}  installing shellcheck $SHELLCHECK_VERSION...${N}"
  local tmp
  tmp="$(mktemp -d)"
  case "$PLAT" in
    linux|darwin)
      curl -fsSL --ssl-no-revoke \
        "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.${PLAT}.${ARCH}.tar.xz" \
        | tar -xJ -C "$tmp"
      mv "$tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" "$SHELLCHECK_BIN"
      chmod +x "$SHELLCHECK_BIN"
      ;;
    windows)
      curl -fsSL --ssl-no-revoke -o "$tmp/sc.zip" \
        "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.zip"
      unzip -q -o "$tmp/sc.zip" -d "$tmp"
      mv "$tmp/shellcheck.exe" "$SHELLCHECK_BIN"
      ;;
    *)
      rm -rf "$tmp"
      return 1
      ;;
  esac
  rm -rf "$tmp"
}

ensure_actionlint() {
  local exe="actionlint"
  [ "$PLAT" = "windows" ] && exe="actionlint.exe"
  ACTIONLINT_BIN="$BIN_DIR/$exe"
  if [ -x "$ACTIONLINT_BIN" ] && "$ACTIONLINT_BIN" -version 2>/dev/null | grep -q "$ACTIONLINT_VERSION"; then
    return 0
  fi
  echo -e "${D}  installing actionlint $ACTIONLINT_VERSION...${N}"
  # actionlint releases use amd64/arm64 in their archive names, not x86_64/aarch64.
  local al_arch
  case "$ARCH" in
    x86_64)   al_arch=amd64 ;;
    aarch64)  al_arch=arm64 ;;
    *)        return 1 ;;
  esac
  local tmp
  tmp="$(mktemp -d)"
  case "$PLAT" in
    linux|darwin)
      curl -fsSL --ssl-no-revoke \
        "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_${PLAT}_${al_arch}.tar.gz" \
        | tar -xz -C "$tmp"
      mv "$tmp/actionlint" "$ACTIONLINT_BIN"
      chmod +x "$ACTIONLINT_BIN"
      ;;
    windows)
      curl -fsSL --ssl-no-revoke -o "$tmp/al.zip" \
        "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_windows_${al_arch}.zip"
      unzip -q -o "$tmp/al.zip" -d "$tmp"
      mv "$tmp/actionlint.exe" "$ACTIONLINT_BIN"
      ;;
    *)
      rm -rf "$tmp"
      return 1
      ;;
  esac
  rm -rf "$tmp"
}

# --- Header ---
echo -e "${B}ClaudeMaxPower — Local CI Verification${N}"
echo -e "${D}Mirrors .github/workflows/ci.yml | cache: $CACHE_DIR${N}"

# --- 1. Shellcheck ---
sec "Validate Shell Scripts  (shellcheck $SHELLCHECK_VERSION)"
if ensure_shellcheck; then
  for path in ".claude/hooks" "workflows" "scripts"; do
    if output=$( "$SHELLCHECK_BIN" "$path"/*.sh 2>&1 ); then
      ok "$path/*.sh"
    else
      no "$path/*.sh"
      echo "    ${output//$'\n'/$'\n    '}"
    fi
  done
else
  no "shellcheck install (unsupported platform: $PLAT/$ARCH)"
fi

# --- 2. actionlint ---
sec "Validate GitHub Actions Workflows  (actionlint $ACTIONLINT_VERSION)"
if ensure_actionlint; then
  if output=$( "$ACTIONLINT_BIN" 2>&1 ); then
    ok ".github/workflows/*.yml"
  else
    no ".github/workflows/*.yml"
    echo "    ${output//$'\n'/$'\n    '}"
  fi
else
  no "actionlint install (unsupported platform: $PLAT/$ARCH)"
fi

# --- 3. JSON ---
sec "Validate JSON Files  (jq)"
if command -v jq >/dev/null 2>&1; then
  for f in .claude/settings.json mcp/github-config.json mcp/sentry-config.json; do
    if jq empty "$f" 2>/dev/null; then ok "$f"; else no "$f"; fi
  done
else
  no "jq not installed (apt install jq | brew install jq | choco install jq)"
fi

# --- 4. Secrets ---
sec "Check for Secrets  (grep)"
if grep -qE "(ghp_[a-zA-Z0-9]{36}|sntrys_[a-zA-Z0-9]+)" .env.example 2>/dev/null; then
  no ".env.example contains real-looking tokens"
else
  ok ".env.example has no real tokens"
fi
if grep -rn -E "ghp_[a-zA-Z0-9]{36}" \
    --include="*.sh" --include="*.md" --include="*.json" --include="*.py" \
    --exclude-dir=".git" . >/dev/null 2>&1; then
  no "found possible GitHub token in source files"
  grep -rn -E "ghp_[a-zA-Z0-9]{36}" \
    --include="*.sh" --include="*.md" --include="*.json" --include="*.py" \
    --exclude-dir=".git" . | sed 's/^/    /' || true
else
  ok "no hardcoded GitHub tokens in source"
fi

# --- 5. Structure ---
sec "Verify Project Structure"
REQUIRED=(
  "CLAUDE.md" "README.md" "LICENSE" ".env.example" ".gitignore"
  ".claude/settings.json"
  ".claude/hooks/session-start.sh" ".claude/hooks/pre-tool-use.sh"
  ".claude/hooks/post-tool-use.sh" ".claude/hooks/stop.sh"
  ".claude/agents/code-reviewer.md" ".claude/agents/security-auditor.md"
  ".claude/agents/doc-writer.md"
  "skills/fix-issue.md" "skills/review-pr.md" "skills/refactor-module.md"
  "skills/tdd-loop.md" "skills/pre-commit.md" "skills/generate-docs.md"
  "workflows/batch-fix.sh" "workflows/parallel-review.sh"
  "workflows/mass-refactor.sh" "workflows/dependency-graph.sh"
  "mcp/github-config.json" "mcp/sentry-config.json"
  "docs/getting-started.md" "docs/hooks-guide.md" "docs/skills-guide.md"
  "docs/agents-guide.md" "docs/troubleshooting.md"
)
missing=()
for f in "${REQUIRED[@]}"; do
  [ -f "$f" ] || missing+=("$f")
done
if [ "${#missing[@]}" -eq 0 ]; then
  ok "all ${#REQUIRED[@]} required files present"
else
  no "${#missing[@]} required file(s) missing"
  for f in "${missing[@]}"; do echo "    $f"; done
fi

# --- 6. Markdown lint ---
# Mirrors the lint-markdown CI job. CI uses `|| true` at the end of the run
# block, so this check is informational — it never gates the build. We do the
# same locally: warnings produce an INFO line, not a FAIL.
sec "Lint Markdown  (markdownlint-cli)"
if command -v markdownlint >/dev/null 2>&1; then
  if [ -f ".markdownlint.json" ] \
     && markdownlint README.md docs/*.md mcp/README.md \
        --config .markdownlint.json >/dev/null 2>&1; then
    ok "markdown clean (with .markdownlint.json)"
  elif markdownlint README.md docs/*.md \
       --disable MD013 MD033 MD041 >/dev/null 2>&1; then
    ok "markdown clean (default rules minus MD013/MD033/MD041)"
  else
    info "markdown warnings present (CI is non-gating for this — informational)"
  fi
else
  skip "markdownlint not installed (npm i -g markdownlint-cli to enable)"
fi

# --- 7. Example tests ---
# Mirrors the test-examples CI job. CI runs `pytest -v --tb=short` with
# continue-on-error: true (informational, since 3 todo-app tests are seeded
# pedagogical bugs), then runs `pytest --collect-only -q` as the gating step.
# We mirror both — the run is INFO, the collection check is OK/FAIL.
sec "Run Example Tests  (pytest in examples/todo-app/.venv)"
VENV_PY=""
if   [ -x "examples/todo-app/.venv/bin/python" ]; then
  VENV_PY="examples/todo-app/.venv/bin/python"
elif [ -x "examples/todo-app/.venv/Scripts/python.exe" ]; then
  VENV_PY="examples/todo-app/.venv/Scripts/python.exe"
fi
if [ -n "$VENV_PY" ]; then
  if "$VENV_PY" -m pytest examples/todo-app/tests/ -q --tb=line >/dev/null 2>&1; then
    info "todo-app tests: all green (CI run step is non-gating regardless)"
  else
    info "todo-app tests: failures present (3 are seeded pedagogical bugs — CI non-gating)"
  fi
  if "$VENV_PY" -m pytest examples/todo-app/tests/ --collect-only -q >/dev/null 2>&1; then
    ok "test collection succeeds (gating in CI)"
  else
    no "test collection failed — pytest cannot import the test suite"
  fi
else
  skip "examples/todo-app/.venv not present (run bash scripts/setup.sh first)"
fi

# --- Summary ---
echo ""
echo -e "${B}============================================${N}"
TOTAL_GATING=$((PASSED + FAILED))
if [ "$FAILED" -eq 0 ]; then
  echo -e "${G}All $PASSED gating checks passed${N} — local matches CI."
else
  echo -e "${R}$FAILED of $TOTAL_GATING gating checks failed${N}"
  for f in "${FAILS[@]}"; do echo "  - $f"; done
fi
# Honesty line: surface non-gating signal so the user sees coverage, not just
# "green". Helps avoid the "verify-ci.sh said green, CI said red" surprise.
EXTRAS=""
if [ "$INFO" -gt 0 ]; then
  EXTRAS="$EXTRAS  ${B}INFO${N}: $INFO non-gating signal(s)"
fi
if [ "$SKIPPED" -gt 0 ]; then
  EXTRAS="$EXTRAS  ${Y}SKIPPED${N}: $SKIPPED check(s) — install missing tooling to enable"
fi
if [ -n "$EXTRAS" ]; then
  echo -e "$EXTRAS"
fi
echo -e "${B}============================================${N}"
if [ "$FAILED" -eq 0 ]; then
  exit 0
else
  exit 1
fi
