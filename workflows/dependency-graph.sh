#!/usr/bin/env bash
# dependency-graph.sh — Generate a dependency visualization using Graphviz
#
# Usage: ./workflows/dependency-graph.sh [--dir <directory>] [--output <file>]
# Example: ./workflows/dependency-graph.sh --dir src/ --output docs/dependency-graph.svg
#
# Requires: graphviz (dot command) — install with: brew install graphviz / apt install graphviz
#
# Workflow:
#   1. Claude analyzes imports/requires across source files
#   2. Outputs a .dot file describing the dependency graph
#   3. dot converts .dot → SVG
#   4. SVG saved to docs/

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SEARCH_DIR="${1:-src}"
OUTPUT_FILE="${2:-docs/dependency-graph.svg}"
DOT_FILE="/tmp/claudemaxpower-deps-$$.dot"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)    SEARCH_DIR="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ClaudeMaxPower — Dependency Graph${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Source dir: $SEARCH_DIR"
echo "Output: $OUTPUT_FILE"
echo ""

# Check graphviz
if ! command -v dot &>/dev/null; then
  echo -e "${YELLOW}Warning: graphviz (dot) not found.${NC}"
  echo "Install with: brew install graphviz (macOS) or apt install graphviz (Linux)"
  echo "Will generate .dot file only."
  SKIP_SVG=true
else
  SKIP_SVG=false
fi

# Step 1: Collect all source files
SOURCE_FILES=$(find "$SEARCH_DIR" \
  \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*" \
  -not -name "*.test.*" \
  -not -name "*.spec.*" \
  2>/dev/null | sort)

if [ -z "$SOURCE_FILES" ]; then
  echo -e "${RED}No source files found in $SEARCH_DIR${NC}"
  exit 1
fi

FILE_COUNT=$(echo "$SOURCE_FILES" | wc -l)
echo "Found $FILE_COUNT source files."

# Step 2: Claude analyzes dependencies
echo ""
echo "Analyzing dependencies..."

FILES_LIST=$(echo "$SOURCE_FILES" | head -50)  # Cap at 50 for large projects

PROMPT="Analyze the import/dependency relationships between the following source files.
For each file, identify what other files in this list it imports from.

Files to analyze:
$FILES_LIST

Output ONLY a valid Graphviz DOT format file. Example format:
digraph Dependencies {
  rankdir=LR;
  node [shape=box, style=filled, fillcolor=lightblue];
  \"module_a\" -> \"module_b\";
  \"module_a\" -> \"module_c\";
}

Rules:
- Node names should be the filename without extension and without path
- Only include edges for imports WITHIN this file list (not external libraries)
- Keep it clean and readable"

DOT_CONTENT=$(claude --print \
  --allowedTools "Read,Grep" \
  "$PROMPT" 2>&1 | grep -A 9999 'digraph' | head -200 || echo "")

if [ -z "$DOT_CONTENT" ]; then
  echo -e "${YELLOW}Could not generate dependency graph from Claude output.${NC}"
  echo "Creating a basic DOT file from import analysis instead..."

  # Fallback: basic Python import analysis
  {
    echo "digraph Dependencies {"
    echo "  rankdir=LR;"
    echo "  node [shape=box, style=filled, fillcolor=lightblue];"
    while IFS= read -r FILE; do
      MODULE=$(basename "$FILE" | sed 's/\.[^.]*$//')
      grep -E "^(from|import) " "$FILE" 2>/dev/null | \
        grep -oE "(from|import) [a-zA-Z0-9_.]+" | \
        awk '{print $2}' | \
        while IFS= read -r DEP; do
          DEP_BASE=$(echo "$DEP" | cut -d. -f1)
          if echo "$SOURCE_FILES" | grep -q "$DEP_BASE"; then
            echo "  \"$MODULE\" -> \"$DEP_BASE\";"
          fi
        done
    done <<< "$SOURCE_FILES"
    echo "}"
  } > "$DOT_FILE"
else
  echo "$DOT_CONTENT" > "$DOT_FILE"
fi

echo "DOT file: $DOT_FILE"

# Step 3: Convert to SVG
mkdir -p "$(dirname "$OUTPUT_FILE")"

if [ "$SKIP_SVG" = false ]; then
  echo "Converting to SVG..."
  if dot -Tsvg "$DOT_FILE" -o "$OUTPUT_FILE" 2>/dev/null; then
    echo -e "${GREEN}Dependency graph saved: $OUTPUT_FILE${NC}"
  else
    echo -e "${RED}SVG conversion failed. DOT file preserved at: $DOT_FILE${NC}"
  fi
else
  DOT_OUTPUT="${OUTPUT_FILE%.svg}.dot"
  cp "$DOT_FILE" "$DOT_OUTPUT"
  echo -e "${GREEN}DOT file saved: $DOT_OUTPUT${NC}"
  echo "Convert to image with: dot -Tsvg $DOT_OUTPUT -o dependency-graph.svg"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""
