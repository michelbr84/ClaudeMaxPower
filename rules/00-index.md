# ClaudeMaxPower — Rules Index

This directory holds the durable rules for the ClaudeMaxPower repository. `CLAUDE.md` at the
repository root is a short entrypoint that links here; the full rule corpus lives in this
directory.

> Rules in this directory take precedence over generic Claude defaults. Subfolder `CLAUDE.md`
> files extend or override rules for their specific context.

## Load Order and Purpose

Files are numbered so a human (or a tooling pipeline) can read them top-to-bottom and reach a
self-consistent understanding of how this project is governed.

| File | Scope |
|------|-------|
| [10-iron-laws.md](10-iron-laws.md) | Non-negotiable project laws — TDD, spec gate, root cause, no merge on red, plus the "Absolute Rules" register that cross-references the rest. |
| [20-workflow.md](20-workflow.md) | Session start protocol, the unified Superpowers + ClaudeMaxPower pipeline, alternate entry points, escalation paths. |
| [30-git-github-ci.md](30-git-github-ci.md) | Branch policy, PR policy, commit-message format, CI expectations, GitHub Actions rules. |
| [40-skills.md](40-skills.md) | Native ClaudeMaxPower skills, Superpowers skills, skill invocation rules, progressive disclosure. |
| [50-tools.md](50-tools.md) | Preferred tool patterns (Glob/Grep/Read/Edit/Write/Bash) and core coding conventions per language. |
| [60-security-privacy.md](60-security-privacy.md) | Secret handling, `.env` policy, destructive-command policy, test-isolation policy. |
| [90-maintenance.md](90-maintenance.md) | Rule hygiene, audit/cleanup conventions, how to add or retire a rule. |

## Conventions

- Each rule file uses ATX headings (`#`).
- A rule is stated once in the most specific file. Broader files reference it rather than
  repeat it.
- Anything marked **clarification** is a disambiguation added during the extraction from the
  former monolithic `CLAUDE.md`; it does not introduce new policy.
- When two files appear to disagree, the more specific file wins. If you find an actual
  contradiction, treat it as a bug — see [90-maintenance.md](90-maintenance.md).

## Related References

- [`../CLAUDE.md`](../CLAUDE.md) — short entrypoint and summary.
- [`../docs/superpowers-integration.md`](../docs/superpowers-integration.md) — how the upstream
  Superpowers methodology integrates with ClaudeMaxPower infrastructure.
- [`../docs/hooks-guide.md`](../docs/hooks-guide.md), [`../docs/skills-guide.md`](../docs/skills-guide.md),
  [`../docs/agents-guide.md`](../docs/agents-guide.md), [`../docs/agent-teams-guide.md`](../docs/agent-teams-guide.md),
  [`../docs/batch-workflows.md`](../docs/batch-workflows.md) — operational guides referenced by the rules.
- [`../ATTRIBUTION.md`](../ATTRIBUTION.md) — third-party content licensing.
