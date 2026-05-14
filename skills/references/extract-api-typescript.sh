#!/usr/bin/env bash
# Extract public TypeScript/JavaScript API surface from a directory.
# Used by /generate-docs Step 2.
#
# Usage: bash skills/references/extract-api-typescript.sh <directory>
#
# Output: one line per export, format: <file>:<line>:<signature>

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

find "$DIR" \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -name "*.test.*" \
  -not -name "*.spec.*" \
  -not -name "*.d.ts" \
  | while read -r f; do
    grep -nE "^export (function|class|const|interface|type|enum|default) " "$f" \
      | while IFS=: read -r line sig; do
        printf '%s:%s:%s\n' "$f" "$line" "$sig"
      done
  done
