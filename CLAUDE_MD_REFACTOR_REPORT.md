# CLAUDE.md Refactor Report

Restructured `CLAUDE.md` to the requested section layout (Project Purpose → Operating
Principles → Non-Negotiable Rules → Workflow → GitHub/CI/Merge Discipline → Skills and Slash
Commands → Rules Index → Verification Commands → Maintenance Notes). The file stays under
the 200-line budget, every durable rule is preserved (mostly by reference into
[`./rules/`](./rules/00-index.md)), and no surrounding code was modified.

## What Changed

- Top-level sections now match the requested taxonomy and order. Old headings (`Project
  Identity`, `Rules`, `At a Glance`, `Skills Available`, `Agents Available`,
  `Documentation References`) replaced/renamed/folded:
  - `Project Identity` → `Project Purpose` (tightened wording; same content; added a
    pointer to `docs/superpowers-integration.md`).
  - `At a Glance` + `Rules` (table) → split into `Operating Principles`,
    `Non-Negotiable Rules`, `Rules Index`.
  - `Skills Available` + `Agents Available` → consolidated into `Skills and Slash
    Commands` (single section).
  - `Documentation References` retained verbatim at the bottom.
- Added two new sections that did not exist before:
  - **Workflow** — the unified pipeline diagram + the shortcuts table, both in the same
    place. Previously the diagram was implicit (only in `rules/20-workflow.md`).
  - **GitHub / CI / Merge Discipline** — a single section that pulls the branch policy,
    commit policy, branch-finish policy, and CI gating/non-gating jobs together at
    summary level. Full table still lives in `rules/30-git-github-ci.md`.
  - **Verification Commands** — names the four supported repo scripts in one place
    (`verify.sh`, `verify-ci.sh`, `validate-skills.sh`, `test-hooks.sh`). Previously a
    reader had to dig into `rules/30-git-github-ci.md` or `rules/90-maintenance.md`.
  - **Maintenance Notes** — three-line policy: edit rules in `./rules/`, follow
    `rules/90-maintenance.md` to add a rule, keep this entrypoint under 200 lines.
- Added one **Operating Principle** that captures rule precedence explicitly (more-specific
  rule file wins; iron laws win over topic rules; in-conversation user instructions win
  over CLAUDE.md). This consolidates two pieces of prose previously scattered across
  `rules/00-index.md` and `rules/90-maintenance.md` — not new policy.

## What Was Preserved

Every durable rule, safety gate, skill reference, branch/PR/CI rule, and privacy/security
rule from the prior `CLAUDE.md` (and from `rules/`) is still present, either inline at
summary level or via an explicit link. Checklist:

| Item | Where in new CLAUDE.md |
|---|---|
| Project description + two modes (new-project / existing-project) | `Project Purpose` |
| `.estado.md` session restore + `.env` warning + area detection | `Operating Principles` |
| Default-to-pipeline rule for ambiguous new work | `Operating Principles` |
| Preferred tool patterns (Glob/Grep/Read/Edit/Write/Bash) | `Operating Principles` |
| Coding conventions (shell `set -euo pipefail`, PEP 8, Markdown ATX/100-char/fenced) | `Operating Principles` |
| Four Iron Laws (TDD, spec gate, root cause, no merge on red) | `Non-Negotiable Rules` |
| Iron Law enforcement mechanism per law (skill names) | `Non-Negotiable Rules` |
| "Never" rules: `rm -rf /`, `.env`/secrets, push to `main`/`master`, skip tests, mock fs/db | `Non-Negotiable Rules` |
| Reviewer-output-is-a-hypothesis rule | `Non-Negotiable Rules` (last paragraph) |
| Full unified-pipeline diagram | `Workflow` |
| Superpowers plugin install command | `Workflow` |
| Shortcuts table (7 entries: fix-issue, review-pr, refactor-module, brainstorm+plans, assemble-team, gen-commit-message, max-power) | `Workflow` |
| Branch policy + force-push backstop hook | `GitHub / CI / Merge Discipline` |
| Conventional Commits format | `GitHub / CI / Merge Discipline` |
| Pre-commit hook (`pre-commit-check.sh`) vs `/gen-commit-message` split | `GitHub / CI / Merge Discipline` |
| Branch-finish rule + Iron Law #4 reference | `GitHub / CI / Merge Discipline` |
| CI gating jobs list (shellcheck, actionlint, jq, secrets, structure, smoke) | `GitHub / CI / Merge Discipline` |
| CI non-gating jobs (markdownlint, todo-app pytest) | `GitHub / CI / Merge Discipline` |
| Native skills table (all 8) | `Skills and Slash Commands` |
| Superpowers `/superpowers:*` namespace | `Skills and Slash Commands` |
| `skills/references/` progressive disclosure | `Skills and Slash Commands` |
| Specialized agents (code-reviewer, security-auditor, doc-writer, team-coordinator) | `Skills and Slash Commands` |
| Full rules directory table (all 8 files) | `Rules Index` |
| Documentation references (the seven `@docs/...` + `@ATTRIBUTION.md`) | `Documentation References` |
| Subfolder CLAUDE.md override precedence | Header note at top |

## What Was Deduped

- **Rules table appeared twice** in the prior CLAUDE.md — once under `Rules` (header
  table) and partially again as the `At a Glance` bullets. Now there is one canonical
  table under `Rules Index`, plus pointed references from each substantive section.
- **Pipeline + entry points + iron-laws** were each restated in two places (the prose
  bullet list and the implicit narrative). Now stated once each — iron laws in
  `Non-Negotiable Rules`, pipeline in `Workflow`, shortcuts in `Workflow`.
- **Tool patterns and conventions** appeared as two adjacent sections (`Core Coding
  Conventions` + `Preferred Tool Patterns`). Collapsed into a single five-bullet
  `Operating Principles` block, with the full convention list still living in
  `rules/50-tools.md`.
- **Skills and Agents** were two parallel sections that both deferred to `rules/40-skills.md`
  anyway. Consolidated.

No durable rule was reworded, weakened, or removed.

## Whether `./rules/` Exists

`./rules/` **exists** in this branch (created earlier on
`chore/extract-rules-from-claude-md` and carried forward into `chore/refine-claude-md`).
Eight files:

```
rules/00-index.md
rules/10-iron-laws.md
rules/20-workflow.md
rules/30-git-github-ci.md
rules/40-skills.md
rules/50-tools.md
rules/60-security-privacy.md
rules/90-maintenance.md
```

`CLAUDE.md` accordingly acts as the short entrypoint and links into each rule file. No
"Future rules extraction" note was needed.

## Final CLAUDE.md Line Count

**194 lines.** Budget: under 200. Headroom: 6 lines.

## Verification

Commands run, in order:

1. `git checkout -b chore/refine-claude-md` → branch created.
2. `wc -l CLAUDE.md` → **194**.
3. `grep -n "rules/" CLAUDE.md` → 24 matches (the entrypoint links into rules from every
   major section).
4. `grep -n "skills" CLAUDE.md` → 11 matches.
5. `git diff --stat CLAUDE.md` → `1 file changed, 159 insertions(+), 96 deletions(-)`.
6. `bash scripts/verify-ci.sh` → **All 11 gating checks passed**, 2 non-gating INFO
   signals unchanged from main (pre-existing markdown warnings; the three pedagogical
   todo-app bug fixtures). No regression introduced.

The diff is documentation-only. No skills, scripts, workflows, package files, or unrelated
docs were modified.

## Stop Conditions Met

- `CLAUDE.md` updated to the requested section structure.
- `CLAUDE.md` is 194 lines (< 200).
- Every durable rule preserved — see the "What Was Preserved" checklist above.
- `CLAUDE_MD_REFACTOR_REPORT.md` exists and is non-empty (this file).
- `git diff` shows only intentional documentation changes.
