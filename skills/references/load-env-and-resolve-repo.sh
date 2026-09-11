#!/usr/bin/env bash
# Load .env (if present) and resolve REPO from $REPO -> $DEFAULT_REPO.
# Shared by /fix-issue and /review-pr Step 1.
#
# Usage:  eval "$(bash skills/references/load-env-and-resolve-repo.sh)"
#
# Output (on stdout, intended to be eval'd):
#   export KEY=<safely-quoted-value>    for every valid KEY=VALUE line in .env
#   export REPO="<owner/repo>"          when REPO or DEFAULT_REPO resolves
#   exit-code 0 with REPO unset         when neither is set — caller must ask the user
#
# Safety: values are re-quoted with printf %q, so command substitutions
# ($(…), backticks) and spaces in .env values are stored as literal text
# instead of executing or word-splitting at eval time.
#
# Exit codes:
#   0 — env loaded (malformed lines are skipped with a stderr warning);
#       check whether $REPO is non-empty before proceeding

set -euo pipefail

if [ -f .env ]; then
  # Filter comments and blank lines, validate KEY=VALUE shape, then export
  # each entry with a shell-quoted value so eval cannot execute it.
  while IFS= read -r line || [ -n "$line" ]; do
    # Tolerate Windows-authored files (CRLF endings).
    line="${line%$'\r'}"
    # Tolerate an explicit `export` prefix.
    case "$line" in
      export\ *) line="${line#export }" ;;
    esac
    case "$line" in
      ''|\#*) continue ;;
      *=*)   ;;
      *)     echo "# malformed .env line ignored: $line" >&2; continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    # Only valid shell identifiers may be exported.
    if ! printf '%s' "$key" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*$'; then
      echo "# malformed .env line ignored (bad key): $line" >&2
      continue
    fi
    # Strip one pair of surrounding quotes; %q re-quotes safely below.
    case "$value" in
      \"*\") value="${value#\"}"; value="${value%\"}" ;;
      \'*\') value="${value#\'}"; value="${value%\'}" ;;
    esac
    printf 'export %s=%q\n' "$key" "$value"
  done < .env
fi

# Resolve REPO: explicit env wins, then DEFAULT_REPO from .env, then empty.
# The expansions must stay literal in the emitted text; the caller's eval
# expands them after the exports above have run.
# shellcheck disable=SC2016
printf 'export REPO="${REPO:-${DEFAULT_REPO:-}}"\n'