# ClaudeMaxPower — Project Instructions

> Root `CLAUDE.md`. Applies to every session in this repository. Subfolder `CLAUDE.md` files
> extend or override these rules for their specific context. The durable rule corpus lives
> in [`./rules/`](./rules/00-index.md) — this file is the short entrypoint that links into
> it.

## Project Purpose

ClaudeMaxPower is an open-source GitHub template that turns Claude Code into a **coordinated
AI engineering team**. It operates in two modes:

1. **New Project Supercharge** — assembles a team (Architect + Implementer + Tester +
   Reviewer + Doc Writer) from day one.
2. **Existing Project Acceleration** — assembles a team tailored to pending work (Analyst +
   parallel Implementers + Reviewer).

Every technique (hooks, skills, agents, teams, memory handoff) is documented, tested, and
ready to adapt. The unified pipeline integrates the upstream Superpowers methodology with
ClaudeMaxPower infrastructure — full design in
[`docs/superpowers-integration.md`](docs/superpowers-integration.md).

## Operating Principles

- **Read first.** Start each session by checking `.estado.md` for prior context. If `.env`
  is missing, warn the user and suggest `bash scripts/setup.sh`. Identify which area of the
  project (hooks / skills / agents / examples / docs) you are in.
- **Ambiguous new work defaults to the pipeline:**
  `brainstorm → spec → plan → execute → review → finish`.
- **Use the dedicated tool, not the shell command.** `Glob` (not `find`), `Grep` (not
  `grep`), `Read` (not `cat`), `Edit` for targeted changes, `Write` only for new files or
  full rewrites, `Bash` only for execution.
- **Match the language of the file you are modifying.** Shell scripts use
  `set -euo pipefail`, quote variables, and use `local` in functions. Python is PEP 8 with
  type hints on public functions, `pytest` for tests, no global state. Markdown uses ATX
  headings, 100-char lines, fenced code blocks with language tags.
- **Rule precedence.** When in doubt: the more specific rule file wins; iron laws win over
  topic rules; user instructions in the conversation win over CLAUDE.md.

Full convention list: [`rules/50-tools.md`](./rules/50-tools.md).

## Non-Negotiable Rules

**The Four Iron Laws** (enforced by skills + hooks; full text and narrow exceptions in
[`rules/10-iron-laws.md`](./rules/10-iron-laws.md)):

1. **No production code without a failing test first.** Enforced by
   `/superpowers:test-driven-development`.
2. **No implementation without an approved spec.** Enforced by the
   `/superpowers:brainstorming` hard gate.
3. **No fixes without root cause investigation.** Enforced by
   `/superpowers:systematic-debugging` Phase 1.
4. **No merging with failing tests.** Enforced by
   `/superpowers:finishing-a-development-branch` verification.

**Absolute "never" rules** (cross-referenced from the Iron Laws register):

- **Never** run `rm -rf /` or any destructive command without explicit user confirmation.
  — [`rules/60-security-privacy.md`](./rules/60-security-privacy.md).
- **Never** commit `.env` or any file containing real secrets or tokens.
  — [`rules/60-security-privacy.md`](./rules/60-security-privacy.md).
- **Never** push to `main` or `master` directly. Always use a feature branch + PR.
  — [`rules/30-git-github-ci.md`](./rules/30-git-github-ci.md).
- **Never** skip tests when they exist. If tests fail, fix the code, not the tests.
  — [`rules/10-iron-laws.md`](./rules/10-iron-laws.md) § Test Discipline.
- **Never** mock the filesystem or database in tests when real implementations are available.
  — [`rules/10-iron-laws.md`](./rules/10-iron-laws.md) § Test Discipline.

Treat subagent / code-reviewer output as a **hypothesis**, not a verdict — verify each claim
against the code before applying it. Details:
[`rules/10-iron-laws.md`](./rules/10-iron-laws.md) § Verifying Subagent Reviews.

## Workflow

```
Idea
 ├─ /superpowers:brainstorming                 → docs/specs/YYYY-MM-DD-<topic>-design.md (hard gate)
 ├─ /superpowers:writing-plans                 → docs/plans/YYYY-MM-DD-<topic>-plan.md
 ├─ /superpowers:using-git-worktrees           → isolated branch workspace
 ├─ /superpowers:subagent-driven-development   → fresh subagent per task + two-stage review
 │    └─ /superpowers:test-driven-development      (strict Red-Green-Refactor)
 │    └─ /superpowers:systematic-debugging         (root cause before fix)
 └─ /superpowers:finishing-a-development-branch → merge / PR / keep / discard + worktree cleanup
```

Methodology skills live upstream — install with
`/plugin install superpowers@claude-plugins-official`.

**Shortcuts** (use only when the full pipeline would add more friction than value):

| Situation                              | Entry point |
|----------------------------------------|-------------|
| Existing GitHub issue                  | `/fix-issue` (escalates to `/superpowers:systematic-debugging` if stuck) |
| Structured PR review                   | `/review-pr` |
| Simple refactor                        | `/refactor-module` |
| Architectural refactor                 | `/superpowers:brainstorming` + `/superpowers:writing-plans` |
| Large feature, multiple disciplines    | `/assemble-team` (enforces brainstorming gate in new-project mode) |
| Conventional Commits message           | `/gen-commit-message` (deterministic checks run automatically via the pre-commit hook) |
| One-command bootstrap                  | `/max-power` |

Escalation paths, "when to use which mode", and session state handoff (`.estado.md` +
Claude Code auto-memory): [`rules/20-workflow.md`](./rules/20-workflow.md).

## GitHub / CI / Merge Discipline

- **Branches** — always a feature branch + PR; no direct push to `main`/`master`. The
  `pre-tool-use.sh` hook blocks force-pushes to `main`/`master` as a backstop.
- **Commits** — Conventional Commits format (`feat:`, `fix:`, `docs:`, `chore:`,
  `refactor:`, `test:`). The deterministic pre-commit checks (secret scan, debug-statement
  scan, large-file warning, linter) run automatically via
  `.claude/hooks/pre-commit-check.sh`. The LLM-judgment portion (proposing the message)
  lives in `/gen-commit-message`.
- **Branch finish** — use `/superpowers:finishing-a-development-branch`; tests must be green
  before merge/PR (Iron Law #4).
- **CI gating jobs** (`.github/workflows/ci.yml`): shellcheck v0.10.0, actionlint 1.7.7,
  `jq empty` on JSON, secret scan, project-structure manifest, cross-platform smoke
  (`validate-skills.sh` + `test-hooks.sh`).
- **CI non-gating jobs**: markdownlint (informational); `examples/todo-app` pytest run
  (3 seeded pedagogical bugs; only `pytest --collect-only` is gating).

Full CI table and mirror-drift caveat between `ci.yml` and `verify-ci.sh`:
[`rules/30-git-github-ci.md`](./rules/30-git-github-ci.md).

## Skills and Slash Commands

**Native ClaudeMaxPower skills** (in `skills/`, invoked with `/skill-name`):

| Skill | Command | Purpose |
|-------|---------|---------|
| max-power | `/max-power` | One-command activation — install, configure, route to your goal |
| assemble-team | `/assemble-team` | Assemble an agent team (enforces brainstorming gate in new-project mode) |
| fix-issue | `/fix-issue` | Fix a GitHub issue end-to-end |
| review-pr | `/review-pr` | Full PR review workflow |
| refactor-module | `/refactor-module` | Safe module refactor with tests |
| generate-docs | `/generate-docs` | Auto-generate docs from code |
| gen-commit-message | `/gen-commit-message` | Read staged diff, propose Conventional Commits message |
| superpowers-redirect | `/superpowers-redirect` | Catches legacy `/brainstorming`-style commands and routes to canonical `/superpowers:*` |

**Upstream Superpowers skills** are under the `/superpowers:*` namespace after installing
the plugin. Heavy reference content for native skills lives in `skills/references/`
(progressive disclosure — loaded on demand).

**Specialized agents** in `.claude/agents/`: `code-reviewer`, `security-auditor`,
`doc-writer`, `team-coordinator`.

Invocation rules and the brainstorming-gate enforcement detail:
[`rules/40-skills.md`](./rules/40-skills.md).

## Rules Index

The full rule corpus lives in [`./rules/`](./rules/00-index.md):

| File | Scope |
|------|-------|
| [`rules/00-index.md`](./rules/00-index.md) | Load order, conventions, related references. |
| [`rules/10-iron-laws.md`](./rules/10-iron-laws.md) | Iron laws, narrow exceptions, Absolute Rules register, test discipline, reviewer-verification rule. |
| [`rules/20-workflow.md`](./rules/20-workflow.md) | Session start, unified pipeline, alternate entry points, escalation, session state handoff. |
| [`rules/30-git-github-ci.md`](./rules/30-git-github-ci.md) | Branch / PR / commit / CI policy. |
| [`rules/40-skills.md`](./rules/40-skills.md) | Skill catalogue, invocation rules, progressive disclosure. |
| [`rules/50-tools.md`](./rules/50-tools.md) | Tool patterns and coding conventions. |
| [`rules/60-security-privacy.md`](./rules/60-security-privacy.md) | Secrets, destructive commands, audit logging. |
| [`rules/90-maintenance.md`](./rules/90-maintenance.md) | How to add, retire, or fix a rule. |

## Verification Commands

Run from the repository root:

- `bash scripts/verify.sh` — installation-readiness (tools, env, hooks, skills, agents, gh
  auth). Set `VERIFY_STRICT_EXAMPLES=1` to treat the seeded todo-app bugs as hard failures.
- `bash scripts/verify-ci.sh` — local mirror of the CI gating jobs with pinned tool
  versions. Honestly reports SKIPPED checks when local tooling is missing.
- `bash scripts/validate-skills.sh` — skill + agent frontmatter validation. `--strict`
  (or `CMP_STRICT_TOOLS=1`) escalates unknown-tool warnings to failures.
- `bash scripts/test-hooks.sh` — hook self-test harness with a working-tree mutation guard.

## Maintenance Notes

- Edit rules in [`./rules/`](./rules/00-index.md), not in this file. When this entrypoint and
  a rule file disagree, the rule file wins — fix the entrypoint the next time you touch it.
- To add a rule, follow [`rules/90-maintenance.md`](./rules/90-maintenance.md): add it to
  the most-specific file, and only register a one-line pointer in
  [`rules/10-iron-laws.md`](./rules/10-iron-laws.md) if it is project-wide non-negotiable.
- `CLAUDE.md` stays under 200 lines and remains useful on its own; it never carries the
  full rule corpus.

## Documentation References

- @docs/hooks-guide.md
- @docs/skills-guide.md
- @docs/agents-guide.md
- @docs/agent-teams-guide.md
- @docs/batch-workflows.md
- @docs/superpowers-integration.md
- @ATTRIBUTION.md
