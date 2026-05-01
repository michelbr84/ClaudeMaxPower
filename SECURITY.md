# Security Policy

## Supported Versions

ClaudeMaxPower is a template repository — users typically clone or fork the
latest `main`. Security fixes land on `main` and on the most recent tagged
release. Older releases do not receive backports.

| Version          | Supported          |
| ---------------- | ------------------ |
| `main` (rolling) | :white_check_mark: |
| Latest tag       | :white_check_mark: |
| Older tags       | :x:                |

If you have a fork or a clone pinned to an older snapshot, rebase onto `main`
to pick up security fixes.

## Reporting a Vulnerability

Please report security issues **privately**, not as a public issue or PR.

**Preferred:** open a [private security advisory][advisory] on this repository.
GitHub keeps the discussion private until a fix is published and lets us
coordinate disclosure with you.

[advisory]: https://github.com/michelbr84/ClaudeMaxPower/security/advisories/new

**Alternate:** if private advisories are unavailable to you, contact the
maintainer through the contact channels on the
[project owner's profile](https://github.com/michelbr84).

When reporting, please include:

- A clear description of the issue and its impact.
- Reproduction steps or a minimal proof-of-concept.
- The commit SHA or release tag where you observed it.
- Any suggested mitigation, if you have one.

### What to expect

- **Acknowledgement** within 72 hours of receipt.
- **Initial assessment** (severity, scope, reproducibility) within 7 days.
- **Status updates** at least every 14 days while the issue is open.
- **Coordinated disclosure**: once a fix lands on `main`, the advisory is
  published with credit to the reporter — unless you ask to remain anonymous.

## In Scope

Examples of issues that ClaudeMaxPower considers in scope:

- A hook script (`session-start.sh`, `pre-tool-use.sh`, `post-tool-use.sh`,
  `stop.sh`) that can be tricked into executing an unintended command or
  exfiltrating data.
- A workflow under `.github/workflows/` that leaks tokens or grants more
  permission than necessary.
- A skill or agent that mishandles `.env`, secrets, or credentials.
- A path-traversal or arbitrary-file-write in any script under `scripts/`,
  `workflows/`, or `.claude/`.
- A bypass of the `BLOCKED_PATTERNS` allow/deny list in `pre-tool-use.sh`
  that would let a clearly-malicious command through.
- Supply-chain risks introduced by `scripts/setup.sh`, the bootstrap prompt,
  or any auto-installed tool.

## Out of Scope

The following are explicitly out of scope for this repository:

- Vulnerabilities in [Claude Code][cc], the [Claude Agent SDK][sdk], or the
  Anthropic API itself. Report those upstream to Anthropic.
- Vulnerabilities in third-party MCP servers configured via `mcp/*.json`.
  Report those to the respective MCP server projects.
- Risks inherent to running an AI coding assistant against your own code
  — the assistant can read or modify any file you authorize it to touch.
  Use Claude Code's permission modes and the hook block-list as defense in
  depth (see `docs/hooks-guide.md`).
- Issues in user-customized hooks, skills, or agents that ClaudeMaxPower
  does not ship by default.
- Findings from automated scanners that have no demonstrable security
  impact (style warnings, informational notices, theoretical risks without
  a concrete attack path).

[cc]: https://www.anthropic.com/claude-code
[sdk]: https://docs.anthropic.com/en/api/agent-sdk

## Defensive Guidance for Users of This Template

If you have installed ClaudeMaxPower into your own project:

- Never commit `.env`, real API tokens, or production credentials. The
  pre-tool-use hook and CI's `Check for Secrets` job are backstops, not
  primary controls.
- Review every PR before merging — Claude-authored commits are not exempt.
- Keep the hooks enabled and treat `pre-tool-use.sh`'s block-list as
  defense in depth, not the primary safety boundary
  (see `docs/hooks-guide.md`).
- Run `bash scripts/test-hooks.sh` and `bash scripts/test-auto-dream.sh`
  after customizing hooks or `auto-dream.sh`.
- Prefer Claude Code's `plan` mode for risky or destructive work.
