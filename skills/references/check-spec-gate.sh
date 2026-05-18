#!/usr/bin/env bash
# Check whether an approved design spec exists in docs/specs/.
# Used by /assemble-team Step 0 (the brainstorming hard gate).
#
# Usage: bash skills/references/check-spec-gate.sh [docs-dir]
#
# Output (stdout): path of the most recent matching spec when one exists.
#
# Exit codes:
#   0 — at least one spec found (most-recent path printed to stdout)
#   1 — no spec found (caller should stop and route to /superpowers:brainstorming)

set -euo pipefail

DOCS_DIR="${1:-docs/specs}"

shopt -s nullglob
specs=( "$DOCS_DIR"/*-design.md )
shopt -u nullglob

if [ "${#specs[@]}" -eq 0 ]; then
  exit 1
fi

# Most-recently modified spec wins. Portable across GNU/BSD stat by using `ls -t`.
ls -t "${specs[@]}" | head -n 1
