#!/usr/bin/env bash
# Route a free-text goal string to a recommended skill.
# Used by /max-power Step 6.1.
#
# Usage: bash skills/references/route-goal.sh "<goal text>"
#
# Output (stdout):
#   <route>\t<rationale>
#
# Exit codes:
#   0 — exactly one route matched (deterministic)
#   1 — multiple routes matched (ambiguous — caller should ask the user)
#   2 — no goal provided
#   3 — no route matched (caller should show the menu)
#
# Matching is case-insensitive, whole-word, first-keyword-wins within each route.
# Order of routes matters: more-specific routes first.

set -euo pipefail

GOAL="${1:-}"
if [ -z "$GOAL" ]; then
  exit 2
fi

# Lowercase for matching.
g="$(printf '%s' "$GOAL" | tr '[:upper:]' '[:lower:]')"

# Each route: <skill>|<one-line rationale>|<space-separated keyword list>
# Note: "build" deliberately appears under "new feature" not "fix", so "rebuild" classifies as a feature.
routes=(
  "/fix-issue|GitHub issue number detected — fix-issue handles it end-to-end with TDD.|#[0-9]"
  "/superpowers:systematic-debugging|Symptom language suggests a bug — start with root cause investigation.|bug fix error broken crash regression"
  "/review-pr|PR/review language detected — review-pr handles the full review flow.|review pr pull request"
  "/refactor-module|Refactor/rename language detected — refactor-module is the safe path with test baseline.|refactor rename extract cleanup"
  "/superpowers:test-driven-development|Test/TDD/coverage language — start with the strict TDD loop.|test tdd coverage"
  "/generate-docs|Docs/readme language — generate-docs scans source and writes docs/api/.|docs readme documentation"
  "/assemble-team|Multiple-task language — assemble-team coordinates parallel agents.|team parallel several tasks"
  "/gen-commit-message|Commit-message language — gen-commit-message reads the staged diff and proposes one.|commit message conventional commit"
  "/superpowers:brainstorming|Feature/build language — brainstorming is the hard gate before any new code.|new feature add build create implement"
)

matched=()
for entry in "${routes[@]}"; do
  IFS='|' read -r skill rationale keywords <<<"$entry"
  for kw in $keywords; do
    # Special-case: issue-number pattern (#NNN)
    if [ "$kw" = "#[0-9]" ]; then
      if printf '%s' "$g" | grep -qE '#[0-9]+'; then
        matched+=("$skill|$rationale")
        break
      fi
      continue
    fi
    # Word-boundary match on lowercased goal.
    if printf '%s' "$g" | grep -qwE "$kw"; then
      matched+=("$skill|$rationale")
      break
    fi
  done
done

case "${#matched[@]}" in
  0) exit 3 ;;
  1)
    IFS='|' read -r skill rationale <<<"${matched[0]}"
    printf '%s\t%s\n' "$skill" "$rationale"
    exit 0
    ;;
  *)
    # Ambiguous — print all matches so the caller can ask the user.
    for m in "${matched[@]}"; do
      IFS='|' read -r skill rationale <<<"$m"
      printf '%s\t%s\n' "$skill" "$rationale"
    done
    exit 1
    ;;
esac
