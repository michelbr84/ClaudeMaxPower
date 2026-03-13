#!/usr/bin/env bash
# parallel-review.sh — Writer/Reviewer pattern using git worktrees
#
# Usage: ./workflows/parallel-review.sh --feature <branch-name> --task <description>
# Example: ./workflows/parallel-review.sh --feature add-search --task "Add search_tasks() function to todo.py"
#
# Pattern:
#   1. Create a worktree for the "Writer" Claude session
#   2. Writer implements the feature in isolation
#   3. Create a second worktree for the "Reviewer" Claude session
#   4. Reviewer reads Writer's diff and produces a structured review
#   5. Report: diff + review side by side

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
FEATURE=""
TASK=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature) FEATURE="$2"; shift 2 ;;
    --task)    TASK="$2";    shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [ -z "$FEATURE" ] || [ -z "$TASK" ]; then
  echo "Usage: $0 --feature <branch> --task <description>"
  exit 1
fi

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}Error:${NC} Not inside a git repository."
  exit 1
fi

MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
WRITER_WORKTREE="/tmp/claudemaxpower-writer-$$"
REVIEWER_WORKTREE="/tmp/claudemaxpower-reviewer-$$"
WRITER_BRANCH="${FEATURE}-writer"
REVIEW_OUTPUT="/tmp/claudemaxpower-review-$$.md"

cleanup() {
  echo ""
  echo "Cleaning up worktrees..."
  git worktree remove --force "$WRITER_WORKTREE" 2>/dev/null || true
  git worktree remove --force "$REVIEWER_WORKTREE" 2>/dev/null || true
  git branch -D "$WRITER_BRANCH" 2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ClaudeMaxPower — Parallel Review${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Feature branch: $FEATURE"
echo "Task: $TASK"
echo ""

# ── PHASE 1: Writer ──────────────────────────────────────────────────────────
echo -e "${BLUE}[1/3] Creating Writer worktree...${NC}"
git worktree add -b "$WRITER_BRANCH" "$WRITER_WORKTREE" "$MAIN_BRANCH"
echo -e "${GREEN}Worktree created at: $WRITER_WORKTREE${NC}"
echo ""

echo -e "${BLUE}[2/3] Writer session: implementing feature...${NC}"
WRITER_PROMPT="You are a developer implementing a feature. Work in directory: $WRITER_WORKTREE

Task: $TASK

Requirements:
- Write the implementation
- Write tests for it
- Make sure all tests pass before finishing
- Commit the changes with a conventional commit message

When done, report: what you implemented and the test results."

if ! claude --print \
  --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
  "$WRITER_PROMPT" 2>&1; then
  echo -e "${YELLOW}Writer session had issues — proceeding to review anyway.${NC}"
fi

echo ""

# ── PHASE 2: Get the diff ────────────────────────────────────────────────────
echo -e "${BLUE}[3/3] Generating diff for review...${NC}"
DIFF=$(git -C "$WRITER_WORKTREE" diff "$MAIN_BRANCH"..."$WRITER_BRANCH" 2>/dev/null || \
       git -C "$WRITER_WORKTREE" diff HEAD~1 2>/dev/null || echo "No diff available")

if [ -z "$DIFF" ] || [ "$DIFF" = "No diff available" ]; then
  echo -e "${YELLOW}Warning: No changes found in writer worktree.${NC}"
else
  echo "Diff generated ($(echo "$DIFF" | wc -l) lines)."
fi

# ── PHASE 3: Reviewer ────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}Reviewer session: reviewing the implementation...${NC}"
git worktree add "$REVIEWER_WORKTREE" "$MAIN_BRANCH"

REVIEWER_PROMPT="You are a senior code reviewer. Review the following diff for the feature: $TASK

Use the code-reviewer agent checklist from .claude/agents/code-reviewer.md.

DIFF TO REVIEW:
\`\`\`diff
$DIFF
\`\`\`

Produce a structured review with: verdict, strengths, blocking issues, suggestions, security notes, test assessment."

REVIEW=$(claude --print \
  --allowedTools "Read,Glob,Grep" \
  "$REVIEWER_PROMPT" 2>&1 || echo "Review session failed.")

# Save review to file
{
  echo "# Parallel Review Report"
  echo ""
  echo "**Feature**: $FEATURE"
  echo "**Task**: $TASK"
  echo "**Date**: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "## Implementation Diff"
  echo ""
  echo '```diff'
  echo "$DIFF"
  echo '```'
  echo ""
  echo "## Review"
  echo ""
  echo "$REVIEW"
} > "$REVIEW_OUTPUT"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Review complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Review saved to: $REVIEW_OUTPUT"
echo ""
cat "$REVIEW_OUTPUT"
