#!/usr/bin/env bash
# Load .env (if present) and resolve REPO from $REPO -> $DEFAULT_REPO.
# Shared by /fix-issue and /review-pr Step 1.
#
# Usage:  eval "$(bash skills/references/load-env-and-resolve-repo.sh)"
#
# Output (on stdout, intended to be eval'd):
#   export REPO="<owner/repo>"          when REPO or DEFAULT_REPO resolves
#   exit-code 0 with REPO unset         when neither is set — caller must ask the user
#
# Exit codes:
#   0 — env loaded; check whether $REPO is non-empty before proceeding
#   2 — .env is malformed (lines that are not KEY=VALUE)

set -euo pipefail

if [ -f .env ]; then
  # Filter comments and blank lines, validate KEY=VALUE shape, then export.
  while IFS= read -r line; do
    case "$line" in
      ''|\#*) continue ;;
      *=*)   printf 'export %s\n' "$line" ;;
      *)     echo "# malformed .env line ignored: $line" >&2 ;;
    esac
  done < .env
fi

# Resolve REPO: explicit env wins, then DEFAULT_REPO from .env, then empty.
printf 'export REPO="${REPO:-${DEFAULT_REPO:-}}"\n'
