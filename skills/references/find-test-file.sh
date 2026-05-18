#!/usr/bin/env bash
# List candidate test-file paths for a given source file, in priority order.
# Used by /refactor-module Step 2 and /fix-issue Step 4.
#
# Usage: bash skills/references/find-test-file.sh <source-file>
#
# Output (stdout): one candidate path per line, in priority order.
#   Only paths that actually exist are printed.
#
# Exit codes:
#   0 — at least one existing test file found
#   1 — no existing test file found (caller decides whether to stop or create one)
#   2 — bad input (no source file given, or it doesn't exist)

set -euo pipefail

SRC="${1:-}"
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "Usage: $0 <existing-source-file>" >&2
  exit 2
fi

dir="$(dirname "$SRC")"
base="$(basename "$SRC")"
name="${base%.*}"
ext="${base##*.}"

candidates=()

case "$ext" in
  py)
    # Walk up from the source file's dir to find a sibling tests/ directory.
    # Covers the common src-layout: pkg/src/foo.py paired with pkg/tests/test_foo.py.
    parent="$(dirname "$dir")"
    candidates+=(
      "${dir}/test_${name}.py"
      "${dir}/tests/test_${name}.py"
      "${parent}/tests/test_${name}.py"
      "${parent}/tests/${name}_test.py"
      "${parent}/test/test_${name}.py"
      "tests/test_${name}.py"
      "tests/${name}_test.py"
      "test/test_${name}.py"
    )
    ;;
  ts|tsx|js|jsx|mjs|cjs)
    candidates+=(
      "${dir}/__tests__/${name}.test.${ext}"
      "${dir}/${name}.test.${ext}"
      "${dir}/${name}.spec.${ext}"
      "__tests__/${name}.test.${ext}"
      "tests/${name}.test.${ext}"
    )
    ;;
  go)
    candidates+=( "${dir}/${name}_test.go" )
    ;;
  rs)
    candidates+=( "${dir}/${name}_test.rs" "tests/${name}.rs" )
    ;;
  rb)
    candidates+=( "spec/${name}_spec.rb" "test/${name}_test.rb" )
    ;;
  *)
    echo "Unsupported extension: .$ext" >&2
    exit 2
    ;;
esac

found=0
for c in "${candidates[@]}"; do
  if [ -f "$c" ]; then
    echo "$c"
    found=1
  fi
done

[ "$found" -eq 1 ] || exit 1
