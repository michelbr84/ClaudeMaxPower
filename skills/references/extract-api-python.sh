#!/usr/bin/env bash
# Extract public Python API surface (def + class) from a directory.
# Used by /generate-docs Step 2.
#
# Usage: bash skills/references/extract-api-python.sh <directory>
#
# Output: one line per definition, format: <file>:<line>:<signature>

set -euo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then
  echo "Usage: $0 <directory>" >&2
  exit 2
fi

if [ ! -d "$DIR" ]; then
  echo "Not a directory: $DIR" >&2
  exit 2
fi

find "$DIR" -name "*.py" \
  -not -path "*/test*" \
  -not -name "__init__.py" \
  -not -path "*/.venv/*" \
  -not -path "*/venv/*" \
  -not -path "*/__pycache__/*" \
  | while read -r f; do
    grep -nE "^(def|class) [a-zA-Z]" "$f" | while IFS=: read -r line sig; do
      printf '%s:%s:%s\n' "$f" "$line" "$sig"
    done
  done
