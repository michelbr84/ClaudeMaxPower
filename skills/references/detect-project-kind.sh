#!/usr/bin/env bash
# Classify a directory as a "new" or "existing" project.
# Used by /max-power Step 1.3.
#
# Usage: bash skills/references/detect-project-kind.sh [directory]
#
# Output (stdout): "new" or "existing"
# Exit codes: 0 always
#
# A directory is "new" when ALL of the following hold:
#   * fewer than 10 non-CMP, non-vendor, non-build files
#   * no README.md OR only the CMP README
#   * no source tree marker (src/, app/, lib/, package.json, pyproject.toml,
#     go.mod, Cargo.toml)
# Otherwise it is "existing".

set -euo pipefail

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
  echo "Not a directory: $DIR" >&2
  exit 2
fi

file_count="$(
  find "$DIR" -type f \
    -not -path "$DIR/.git/*" \
    -not -path "$DIR/.claude/*" \
    -not -path "$DIR/skills/*" \
    -not -path "$DIR/docs/*" \
    -not -path "$DIR/scripts/*" \
    -not -path "$DIR/workflows/*" \
    -not -path '*/node_modules/*' \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' \
    -not -path '*/target/*' \
    | wc -l
)"
file_count="${file_count//[[:space:]]/}"

has_real_readme="no"
if [ -f "$DIR/README.md" ]; then
  if ! grep -q "ClaudeMaxPower" "$DIR/README.md"; then
    has_real_readme="yes"
  fi
fi

has_source_tree="no"
for marker in src app lib package.json pyproject.toml go.mod Cargo.toml; do
  if [ -e "$DIR/$marker" ]; then
    has_source_tree="yes"
    break
  fi
done

if [ "$file_count" -lt 10 ] && [ "$has_real_readme" = "no" ] && [ "$has_source_tree" = "no" ]; then
  echo "new"
else
  echo "existing"
fi
