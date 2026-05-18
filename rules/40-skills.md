# 40 — Skills

Native ClaudeMaxPower skills, Superpowers methodology skills, invocation rules, and
progressive-disclosure conventions for reference content.

## Native ClaudeMaxPower Skills

The following skills live in `skills/` and are invoked with `/skill-name`. There are eight.

| Skill | Command | Purpose |
|-------|---------|---------|
| max-power | `/max-power` | One-command activation — install, configure, route to your goal |
| assemble-team | `/assemble-team` | Assemble an agent team (enforces brainstorming gate in new-project mode) |
| fix-issue | `/fix-issue` | Fix a GitHub issue end-to-end |
| review-pr | `/review-pr` | Full PR review workflow |
| refactor-module | `/refactor-module` | Safe module refactor with tests |
| generate-docs | `/generate-docs` | Auto-generate docs from code |
| gen-commit-message | `/gen-commit-message` | Read staged diff, propose Conventional Commits message |
| superpowers-redirect | `/superpowers-redirect` | Catches old `/brainstorming`-style commands and routes to canonical `/superpowers:*` |

## Superpowers Methodology Skills

The methodology skills (brainstorming, plans, TDD, debugging, worktrees, finish) live
upstream in the Superpowers plugin. Install with:

```
/plugin install superpowers@claude-plugins-official
```

Invoke them with the `/superpowers:*` namespace. The full pipeline that wires them together
is documented in [20-workflow.md](20-workflow.md), and the integration design lives in
[`../docs/superpowers-integration.md`](../docs/superpowers-integration.md).

If a user types a legacy unqualified name (`/brainstorming`, `/tdd-loop`, etc.), the
`/superpowers-redirect` skill catches it and points to the canonical replacement.

## Progressive Disclosure: `skills/references/`

Heavy reference content — long checklists, role catalogues, install scripts, helper one-liners
— lives under `skills/references/` instead of being inlined into the skill body. The skill
points to the reference file when it needs the content; Claude reads it on demand rather than
on every session start.

When you write a new skill: if the body grows past ~150 lines or contains a long table /
checklist / template that would be useful to other skills, extract it to
`skills/references/<topic>.md` and reference it from the skill body.

## Skill Frontmatter Validation

Run `bash scripts/validate-skills.sh` after editing or adding a skill to confirm:

- The YAML frontmatter has the required fields.
- Every entry in `allowed-tools` is a recognised Claude Code tool.

Unknown tools are warnings by default; `--strict` (or `CMP_STRICT_TOOLS=1`) escalates them to
failures. The known-tool list lives in `scripts/known-claude-tools.txt` — append to it when
Claude Code introduces a new tool you want to use.

This script also runs in CI as part of the `Cross-Platform Smoke` job — see
[30-git-github-ci.md](30-git-github-ci.md).

## Agents

Specialized agents live in `.claude/agents/`:

- `code-reviewer` — strict code review with project memory.
- `security-auditor` — OWASP-based vulnerability scanning.
- `doc-writer` — documentation generation with user memory.
- `team-coordinator` — orchestrates agent teams with task dependencies.

Operational details: [`../docs/agents-guide.md`](../docs/agents-guide.md),
[`../docs/agent-teams-guide.md`](../docs/agent-teams-guide.md).

## Invocation Discipline

- The deterministic pre-commit checks (secret scan, debug-statement scan, large-file warning,
  linter) run automatically via `.claude/hooks/pre-commit-check.sh` — no skill invocation is
  needed before `git commit`. The LLM portion (proposing a Conventional Commits message)
  lives in `/gen-commit-message`.
- `/assemble-team --mode new-project` enforces the brainstorming gate: a spec must exist
  before the team is assembled. If no spec is present, the skill directs the user to
  `/superpowers:brainstorming` first. `--mode existing-project` does not enforce the gate,
  because the existing codebase serves as the specification of how things currently behave.
- Skills should never weaken an iron law from [10-iron-laws.md](10-iron-laws.md). When a
  skill's workflow appears to short-circuit an iron law, the iron law wins.
