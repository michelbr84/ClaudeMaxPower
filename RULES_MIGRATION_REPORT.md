# Rules Migration Report

Extracted the durable rule corpus from the monolithic root `CLAUDE.md` into a first-class
`./rules/` directory. `CLAUDE.md` is now a short entrypoint that links into it. No rule was
deleted or weakened.

## Files Created

| File | Purpose |
|---|---|
| `rules/00-index.md` | Overview, load order, file scope table, conventions. |
| `rules/10-iron-laws.md` | The Four Iron Laws (TDD, spec gate, root cause, no merge on red), narrow exceptions, the **Absolute Rules Register** (single source of truth that cross-references the rest), test-discipline rules, and the "verifying subagent reviews" iron-law variant. |
| `rules/20-workflow.md` | Session start protocol, the unified Superpowers + ClaudeMaxPower pipeline (ASCII diagram), alternate entry points, "when to use which execution mode", escalation paths, session state handoff (`.estado.md` + Claude Code auto-memory). |
| `rules/30-git-github-ci.md` | Branch policy (no direct push to `main`/`master`), commit-message format (Conventional Commits), branch-finishing skill, CI expectations with pinned tool versions, mirror-drift clarification between `ci.yml` and `verify-ci.sh`. |
| `rules/40-skills.md` | Native ClaudeMaxPower skills table (all 8), Superpowers methodology skills, progressive-disclosure rule (`skills/references/`), skill frontmatter validation, agents inventory, invocation discipline (pre-commit hook vs `/gen-commit-message`, `/assemble-team` gate). |
| `rules/50-tools.md` | Preferred tool patterns (Glob/Grep/Read/Edit/Write/Bash) and core coding conventions per language (Shell, Python, Markdown). |
| `rules/60-security-privacy.md` | Destructive-command policy, secret handling, hook + CI enforcement layers, audit logging, pointer to test-isolation rule in iron-laws. |
| `rules/90-maintenance.md` | Adding a new rule, retiring a rule, avoiding duplication, resolving contradictions, validating the directory, what to do when `CLAUDE.md` and `rules/` disagree. |

## Sections Moved from CLAUDE.md

The old `CLAUDE.md` had nine substantive sections (after "Project Identity"). Mapping:

| Old CLAUDE.md section | New location |
|---|---|
| Session Start Protocol | `rules/20-workflow.md` § Session Start Protocol |
| The Unified Pipeline (Superpowers + ClaudeMaxPower) | `rules/20-workflow.md` § The Unified Pipeline + § Alternate Entry Points |
| The Four Iron Laws | `rules/10-iron-laws.md` § The Four Iron Laws |
| Core Coding Conventions | `rules/50-tools.md` § Core Coding Conventions |
| Absolute Rules (Never Break These) — `rm -rf /` line | `rules/60-security-privacy.md` § Destructive Commands (with one-line entry in iron-laws Register) |
| Absolute Rules — `.env` / secrets line | `rules/60-security-privacy.md` § Secret Handling (with one-line entry in iron-laws Register) |
| Absolute Rules — no push to `main`/`master` line | `rules/30-git-github-ci.md` § Branch Policy (with one-line entry in iron-laws Register) |
| Absolute Rules — never skip tests line | `rules/10-iron-laws.md` § Test Discipline (referenced from iron-laws Register) |
| Absolute Rules — no mock fs/db line | `rules/10-iron-laws.md` § Test Discipline (referenced from iron-laws Register) |
| Preferred Tool Patterns | `rules/50-tools.md` § Preferred Tool Patterns |
| Skills Available | Retained as a summary in `CLAUDE.md`; full invocation rules in `rules/40-skills.md` |
| Agents Available | Retained as a summary in `CLAUDE.md`; also listed in `rules/40-skills.md` |
| Documentation References | Retained verbatim in `CLAUDE.md` |

Content additionally folded in from `docs/superpowers-integration.md` (already in the
project, referenced by `CLAUDE.md`) to enrich the rule files without inventing new policy:

- "When to Use Which Execution Mode" table → `rules/20-workflow.md`.
- "Escalation paths" → `rules/20-workflow.md`.
- Iron-law exceptions and the "verifying subagent reviews" guidance → `rules/10-iron-laws.md`.
- Session state handoff (`.estado.md` + Claude Code auto-memory) → `rules/20-workflow.md`.

These were already authoritative for the project; relocating their headline rules into
`rules/` makes them discoverable as rules rather than as integration prose. The full prose
remains in `docs/superpowers-integration.md`.

## Rules Deduped

The five lines of the old "Absolute Rules (Never Break These)" section overlapped with
several topic-specific concerns. To honour the "rule stated once" constraint:

- Each absolute rule is stated **once** in its most-specific topic file (security, git/CI,
  or test discipline).
- `rules/10-iron-laws.md` contains an **Absolute Rules Register** — a one-line-each table
  that links to the owning file. This is the explicit exception to the "no duplication"
  rule, justified in `rules/90-maintenance.md`: it lets a reader see the complete inventory
  of non-negotiables without opening every file.

Other overlapping content (the unified-pipeline diagram, the iron-laws prose) appeared in
both old `CLAUDE.md` and `docs/superpowers-integration.md`. The new rule files become the
canonical reference; `docs/superpowers-integration.md` remains the integration design
narrative. They are no longer duplicates in the rule-corpus sense, just complementary views.

## Ambiguities Found

Two items required interpretation; both are marked as **clarification** in the rule files.

1. **Two "Absolute Rules" cross-cut topics.** "Never skip tests when they exist" and "never
   mock the filesystem or database when real implementations are available" are absolute
   *and* test-specific. The user's suggested structure had no test-rules file. Resolution:
   placed them in `rules/10-iron-laws.md` under "Test Discipline" because they share
   epistemic ground with Iron Law #1 (TDD), and registered them in the Absolute Rules
   Register. No new policy.
2. **`scripts/verify-ci.sh` REQUIRED list and `.github/workflows/ci.yml` `check-structure`
   REQUIRED list are duplicated.** This is an existing project fact (`verify-ci.sh` even
   warns about it in a comment block). Surfaced as a "clarification" in
   `rules/30-git-github-ci.md` so future readers know mirrors must move together.

No durable rule was reinterpreted, weakened, or invented.

## Verification

Commands run, in order:

1. `git checkout -b chore/extract-rules-from-claude-md` — branch created.
2. `bash scripts/verify-ci.sh` — mirrors the CI gating jobs locally with pinned tool
   versions (shellcheck v0.10.0, actionlint 1.7.7).
   - Result: **All 11 gating checks passed**. Two non-gating INFO lines (markdown warnings
     pre-existing; todo-app pedagogical bug fixtures) — unchanged from a clean main.
3. `bash scripts/validate-skills.sh` — skill + agent frontmatter validation.
   - Result: **All 12 entries PASS** (8 skills + 4 agents). No skills modified.
4. `bash scripts/test-hooks.sh` — hook self-test harness.
   - Result: **All 21 hook self-tests passed**, including the working-tree mutation guard
     ("repo working tree unchanged").
5. Relative-link spot check for every `../` link in `rules/*.md`:

   ```
   for f in CLAUDE.md docs/hooks-guide.md docs/skills-guide.md docs/agents-guide.md \
            docs/agent-teams-guide.md docs/batch-workflows.md docs/superpowers-integration.md \
            ATTRIBUTION.md; do
     [ -f "$f" ] && echo "OK: $f" || echo "MISSING: $f"
   done
   ```

   Result: **all 8 link targets resolve**.

6. `git status --short` after edits — only `CLAUDE.md` modified plus new `rules/` and the new
   `RULES_MIGRATION_REPORT.md`. The pre-existing untracked files
   (`.claude/scheduled_tasks.lock`, `AUDIT_REPORT.md`) are unrelated and unchanged.

## Stop Conditions Met

- `./rules/` exists with 8 markdown files (`00-index.md`, `10-iron-laws.md`, `20-workflow.md`,
  `30-git-github-ci.md`, `40-skills.md`, `50-tools.md`, `60-security-privacy.md`,
  `90-maintenance.md`).
- `CLAUDE.md` updated as a concise index that links to `./rules/00-index.md` and to each
  individual rule file. Skill catalogue and Documentation References preserved verbatim.
- `RULES_MIGRATION_REPORT.md` exists and is non-empty (this file).
- Validation has been run — see "Verification" section above.
- `git diff` shows only the intended rule-organization changes (`CLAUDE.md` rewrite, new
  `rules/` directory, this report). No skill files were touched. No unrelated files were
  touched.
