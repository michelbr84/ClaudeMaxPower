# Skills Audit — 2026-05-14

Structural audit of `skills/*.md` against Anthropic's official Claude Code skill engineering
guidance. Performed by the `claude-code-guide` agent and a parallel `Explore` agent that
catalogued frontmatter and structural metrics.

## Scope

14 skill files under `skills/` were audited against this 5-point checklist:

1. **Wrong Primitive** — does the work actually need to be a skill, or would a hook, a rule
   in `CLAUDE.md`, a CLI script, or an agent be a better fit?
2. **Name & Description Budget** — name uniquely descriptive, description trigger-heavy and
   lean.
3. **Progressive Disclosure** — does the skill load reference content only on demand, or is
   everything inlined into one giant blob?
4. **UX (interview before firing)** — does the skill use `AskUserQuestion` (or equivalent)
   to gather missing prerequisites?
5. **Feedback Loops** — does the skill end with reverse-metaprompting (1–10 rating, faster
   path)?

## Headline finding

Half the skill library (7/14) was deprecated stubs that just redirected to
`/superpowers:*` — they each loaded ~21 lines into every session for no value. Of the 7
active skills, none used progressive disclosure, none used `AskUserQuestion` for missing
arguments, only `assemble-team` produced any structured closing output, and `pre-commit.md`
was the wrong primitive (mostly mechanical `bash` checks that belong in a hook).

Names and descriptions were fine — no overlap, all under 250 chars.

## Per-skill verdict (state at 2026-05-14, before changes)

| Skill | Lines | Verdict | Primary issue |
|---|---|---|---|
| `fix-issue.md` | 102 | KEEP, edit | No `--repo` gate; no feedback loop |
| `review-pr.md` | 123 | KEEP, edit | Inline checklist (extract); no `--repo` gate; no "post or edit?" confirmation |
| `refactor-module.md` | 88 | KEEP, edit | No feedback loop (otherwise clean) |
| `pre-commit.md` | 114 | **DEMOTE** | Mechanical checks belong in a hook; only commit-message generation is LLM work |
| `generate-docs.md` | 107 | KEEP, edit | Inline language-specific extraction (extract); no writability check; no feedback loop |
| `max-power.md` | 331 | KEEP, edit | Massive monolith; install strategies, status dashboard, cross-references should be reference files |
| `assemble-team.md` | 216 | KEEP, edit | Inline team-roster table (extract); existing-project gate too soft; no feedback prompt |
| `brainstorming.md` | 21 | **DELETE** | Deprecated stub → redirect to `/superpowers:brainstorming` |
| `finish-branch.md` | 21 | **DELETE** | Deprecated stub |
| `subagent-dev.md` | 21 | **DELETE** | Deprecated stub |
| `systematic-debugging.md` | 21 | **DELETE** | Deprecated stub |
| `tdd-loop.md` | 21 | **DELETE** | Deprecated stub |
| `using-worktrees.md` | 21 | **DELETE** | Deprecated stub |
| `writing-plans.md` | 21 | **DELETE** | Deprecated stub |

## Cross-cutting findings

1. **No skill used `AskUserQuestion`.** All 7 active skills assumed their arguments arrived
   correctly or failed silently when they did not.
2. **No skill closed with a feedback prompt.** Reverse metaprompting was absent — skills
   never iteratively learned from real use.
3. **No skill used progressive disclosure.** Zero references to helper files, Python scripts,
   or external reference markdown. Everything was inlined in the `.md`.
4. **No skill name overlapped with another.** Names were fine.
5. **All descriptions were under 250 characters.** Description budget was not a problem.
6. **Token waste from deprecated stubs was real but bounded.** ~21 lines × 7 files ≈ 147
   lines of dead text loaded every session.

## Changes applied on 2026-05-14

### Part A — Consolidate deprecated stubs
- Deleted: `skills/brainstorming.md`, `skills/finish-branch.md`, `skills/subagent-dev.md`,
  `skills/systematic-debugging.md`, `skills/tdd-loop.md`, `skills/using-worktrees.md`,
  `skills/writing-plans.md`.
- Created: `skills/superpowers-redirect.md` — single skill with trigger-heavy description
  listing every old slash command, mapping each to its `/superpowers:*` canonical
  replacement, and providing the plugin-install hint.

### Part B — Demote `pre-commit` mechanical checks to a hook
- Created: `.claude/hooks/pre-commit-check.sh` — runs secret scan (blocking), debug-statement
  scan (warn), large-file warning, `flake8`/`eslint` linter passes. Filters internally for
  `git commit` invocations only.
- Updated: `.claude/settings.json` — added the new hook as a second `PreToolUse` Bash entry
  alongside the existing `pre-tool-use.sh` block-list.
- Created: `skills/gen-commit-message.md` — small skill (~70 lines) that reads the staged
  diff and proposes a Conventional Commits message, with a closing "use / edit / regenerate"
  prompt.
- Deleted: `skills/pre-commit.md`.

### Part C — Progressive disclosure for the largest active skills
- Created `skills/references/` folder.
- Extracted `skills/references/team-roster.md` from `assemble-team.md` Step 3 (role
  catalogue, composition rules, spawn order, dependency policy).
- Extracted `skills/references/review-pr-checklist.md` from `review-pr.md` Step 3 (full
  Correctness/Security/Tests/Style/Breaking/Operational checklist).
- Extracted `skills/references/max-power-install-strategies.md` from `max-power.md` Step 2
  (in-place, subdirectory, and tarball-fallback install commands).
- Extracted `skills/references/max-power-status-dashboard.md` from `max-power.md` Step 7
  (status block template).
- Extracted `skills/references/extract-api-python.sh` and
  `skills/references/extract-api-typescript.sh` from `generate-docs.md` Step 2 (API surface
  extraction one-liners).

### Part D — UX gates (missing prerequisite handling)
- `fix-issue.md` Step 1: stop and ask the user for `owner/repo` if `REPO` is unresolved
  after `.env` load. Stop and ask for `ISSUE` if missing.
- `review-pr.md` Step 1: same `REPO` and `PR` gates.
- `review-pr.md` Step 5 (new): confirm "post / edit / cancel" before posting the review.
- `generate-docs.md` Step 0 (new): validate `--dir` is readable and the output target is
  writable; ask for an alternative if not.
- `assemble-team.md` Step 0: hardened the existing-project vague-goals branch from "suggest"
  to "stop and ask explicitly with default no".

### Part E — Feedback loops
Added a standardized closing prompt to every active skill (`fix-issue`, `review-pr`,
`refactor-module`, `generate-docs`, `max-power`, `assemble-team`, `gen-commit-message`,
`superpowers-redirect`):

> **Feedback:** Did this skill do what you needed? Reply with a 1–10 rating, what slowed
> you down, or a faster path from where you started to where you ended.

### Part F — Durable record
This file (`docs/skills-audit-2026-05-14.md`).

### Part G — Documentation alignment
- Updated `CLAUDE.md` skill tables to reflect the new shape (8 skills, 1 new hook).
- Updated `docs/skills-guide.md` to add the `Progressive disclosure: skills/references/`
  subsection and refresh the skill list.
- Updated `docs/hooks-guide.md` to add the `pre-commit-check.sh` entry alongside the
  existing four hooks.

## State after changes

| Metric | Before | After |
|---|---|---|
| Skill files | 14 | 8 |
| Deprecated stubs | 7 | 0 (consolidated into `superpowers-redirect`) |
| Reference files (progressive disclosure) | 0 | 6 |
| Hooks | 4 | 5 (added `pre-commit-check.sh`) |
| Skills with UX gates on missing args | 0 | 5 |
| Skills with closing feedback prompts | 0 | 8 |

Active skills after changes: `assemble-team`, `fix-issue`, `gen-commit-message`,
`generate-docs`, `max-power`, `refactor-module`, `review-pr`, `superpowers-redirect`.

## How to compare against future audits

Run the same 5-point checklist against `skills/*.md` and produce a new audit document at
`docs/skills-audit-YYYY-MM-DD.md`. Diff against this document to see drift in skill count,
reference-file coverage, UX gate adoption, and feedback prompt coverage.
