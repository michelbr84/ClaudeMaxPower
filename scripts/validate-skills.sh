#!/usr/bin/env bash
# validate-skills.sh — Lightweight schema check for skill and agent frontmatter.
#
# Verifies that every file in skills/ and .claude/agents/ has:
#   * a YAML frontmatter block delimited by --- markers
#   * a non-empty `name` field
#   * a non-empty `description` field
#   * an `allowed-tools:` list with at least one entry
#   * (warning) every entry in allowed-tools is in scripts/known-claude-tools.txt
#
# Unknown tool names are warnings by default — Claude Code adds tools over time
# and we don't want CI to break the moment a new one ships. Pass --strict (or
# set CMP_STRICT_TOOLS=1) to fail on unknown tools.
#
# Usage:
#   bash scripts/validate-skills.sh [--strict]
#
# Exit codes:
#   0 — all files pass required-field checks
#   1 — at least one file failed a required-field check, or --strict and unknown tools

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

STRICT="${CMP_STRICT_TOOLS:-0}"
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOWLIST="$REPO_ROOT/scripts/known-claude-tools.txt"

if [ ! -f "$ALLOWLIST" ]; then
  echo -e "${RED}error:${NC} allowlist not found: $ALLOWLIST" >&2
  exit 2
fi

# Build a lookup pattern of known tools (one per line, comments/blank stripped).
KNOWN_TOOLS="$(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST" || true)"

errors=0
warnings=0

check_file() {
  local file="$1"
  local rel="${file#"$REPO_ROOT"/}"
  local in_fm=0
  local seen_open=0
  local name=""
  local description=""
  local in_tools=0
  local tool_count=0
  local unknown_tools=()
  local line tool

  # Read the file line by line, stopping at the closing --- of the frontmatter.
  while IFS= read -r line; do
    if [ "$in_fm" -eq 0 ]; then
      if [ "$line" = "---" ]; then
        in_fm=1
        seen_open=1
        continue
      else
        # First non-empty line was not '---' — no frontmatter.
        if [ -n "$line" ]; then
          break
        fi
        continue
      fi
    fi

    if [ "$line" = "---" ]; then
      in_fm=0
      break
    fi

    case "$line" in
      name:*)
        name="${line#name:}"
        name="${name# }"
        in_tools=0
        ;;
      description:*)
        description="${line#description:}"
        description="${description# }"
        in_tools=0
        ;;
      allowed-tools:*)
        in_tools=1
        ;;
      "  - "*)
        if [ "$in_tools" -eq 1 ]; then
          tool="${line#  - }"
          tool_count=$((tool_count + 1))
          if [ -z "$tool" ]; then
            echo -e "${RED}[FAIL]${NC} $rel — empty allowed-tools entry"
            errors=$((errors + 1))
          elif ! printf '%s\n' "$KNOWN_TOOLS" | grep -qx -- "$tool"; then
            unknown_tools+=("$tool")
          fi
        fi
        ;;
      "  "*)
        # Continuation of a previous list (e.g. arguments). Keep in_tools state.
        ;;
      *)
        # New top-level key — exit any open list.
        in_tools=0
        ;;
    esac
  done < "$file"

  if [ "$seen_open" -eq 0 ]; then
    echo -e "${RED}[FAIL]${NC} $rel — no YAML frontmatter (missing opening ---)"
    errors=$((errors + 1))
    return
  fi

  if [ -z "$name" ]; then
    echo -e "${RED}[FAIL]${NC} $rel — missing or empty 'name' field"
    errors=$((errors + 1))
  fi

  if [ -z "$description" ]; then
    echo -e "${RED}[FAIL]${NC} $rel — missing or empty 'description' field"
    errors=$((errors + 1))
  fi

  if [ "$tool_count" -eq 0 ]; then
    echo -e "${RED}[FAIL]${NC} $rel — missing or empty 'allowed-tools' list"
    errors=$((errors + 1))
  fi

  if [ "${#unknown_tools[@]}" -gt 0 ]; then
    local label="WARN"
    local color="$YELLOW"
    if [ "$STRICT" = "1" ]; then
      label="FAIL"
      color="$RED"
      errors=$((errors + ${#unknown_tools[@]}))
    else
      warnings=$((warnings + ${#unknown_tools[@]}))
    fi
    for tool in "${unknown_tools[@]}"; do
      echo -e "${color}[$label]${NC} $rel — unknown tool '$tool' (not in known-claude-tools.txt)"
    done
  fi

  if [ "$errors" -eq 0 ] && [ "${#unknown_tools[@]}" -eq 0 ]; then
    echo -e "${GREEN}[PASS]${NC} $rel"
  fi
}

echo ""
echo -e "${BLUE}== Validate Skill and Agent Frontmatter ==${NC}"
echo ""

if [ "$STRICT" = "1" ]; then
  echo "Strict mode: unknown tools count as failures."
else
  echo "Lenient mode (default): unknown tools are warnings; --strict to enforce."
fi
echo ""

shopt -s nullglob
files=( "$REPO_ROOT"/skills/*.md "$REPO_ROOT"/.claude/agents/*.md )
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
  echo -e "${RED}error:${NC} no skill or agent files found" >&2
  exit 2
fi

for f in "${files[@]}"; do
  check_file "$f"
done

echo ""
echo "============================================"
if [ "$errors" -eq 0 ]; then
  if [ "$warnings" -gt 0 ]; then
    echo -e "${GREEN}All required-field checks passed${NC} ($warnings unknown-tool warning(s))."
  else
    echo -e "${GREEN}All checks passed.${NC}"
  fi
  exit 0
else
  echo -e "${RED}$errors check(s) failed.${NC}"
  exit 1
fi
