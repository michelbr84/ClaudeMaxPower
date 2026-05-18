#!/usr/bin/env bash
# Regenerate docs/api/README.md from every *.md file in docs/api/.
# Used by /generate-docs Step 4.
#
# Usage: bash skills/references/update-docs-index.sh [docs-api-dir]
#
# Output: writes <dir>/README.md (overwriting). Prints the count of modules indexed.
# Exit codes:
#   0 — README.md written
#   1 — directory has no module files (nothing to index)
#   2 — bad input
#
# Convention:
#   * Module name = first H1 line ("# foo")
#   * One-liner   = first blockquote line that immediately follows the H1 ("> ...")
#                   or, if no blockquote, the first non-empty paragraph line.

set -euo pipefail

DIR="${1:-docs/api}"

if [ ! -d "$DIR" ]; then
  echo "Not a directory: $DIR" >&2
  exit 2
fi

shopt -s nullglob
modules=( "$DIR"/*.md )
shopt -u nullglob

# Drop README.md itself from the input set.
filtered=()
for f in "${modules[@]}"; do
  case "$(basename "$f")" in
    README.md) continue ;;
    *) filtered+=( "$f" ) ;;
  esac
done

if [ "${#filtered[@]}" -eq 0 ]; then
  exit 1
fi

# Sort alphabetically for stable output.
IFS=$'\n' sorted=( $(printf '%s\n' "${filtered[@]}" | sort) )
unset IFS

out="$DIR/README.md"
{
  echo "# API Reference"
  echo ""
  echo "| Module | Description |"
  echo "|--------|-------------|"

  for f in "${sorted[@]}"; do
    base="$(basename "$f" .md)"
    title="$(awk '/^# / { sub(/^# /, ""); print; exit }' "$f")"
    [ -z "$title" ] && title="$base"

    # Prefer the first blockquote line after the H1; fall back to the first
    # non-empty, non-heading line.
    desc="$(awk '
      /^# / { seen=1; next }
      seen && /^> / { sub(/^> /, ""); print; exit }
      seen && /^[^#> ]/ && NF > 0 { print; exit }
    ' "$f")"
    [ -z "$desc" ] && desc="(no description)"

    printf '| [%s](%s.md) | %s |\n' "$base" "$base" "$desc"
  done
} > "$out"

echo "${#sorted[@]} module(s) indexed -> $out"
