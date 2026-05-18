#!/usr/bin/env bash
# Detect the project's tech stack by probing manifest files.
# Shared by /max-power Step 1.4 and /assemble-team Step 2.
#
# Usage: bash skills/references/detect-stack.sh [directory]
#
# Output: comma-separated list of detected stacks on stdout, or "none" if nothing matched.
# Detection is order-stable so consumers can diff results across runs.

set -euo pipefail

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
  echo "Not a directory: $DIR" >&2
  exit 2
fi

stacks=()

[ -f "$DIR/package.json" ]      && stacks+=("node")
{ [ -f "$DIR/requirements.txt" ] || [ -f "$DIR/pyproject.toml" ] || [ -f "$DIR/Pipfile" ]; } \
                                && stacks+=("python")
[ -f "$DIR/go.mod" ]            && stacks+=("go")
[ -f "$DIR/Cargo.toml" ]        && stacks+=("rust")
{ [ -f "$DIR/pom.xml" ] || [ -f "$DIR/build.gradle" ] || [ -f "$DIR/build.gradle.kts" ]; } \
                                && stacks+=("jvm")
[ -f "$DIR/Gemfile" ]           && stacks+=("ruby")

if [ "${#stacks[@]}" -eq 0 ]; then
  echo "none"
else
  ( IFS=','; echo "${stacks[*]}" )
fi
