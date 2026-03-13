# MCP Integrations

This directory contains MCP (Model Context Protocol) server configurations for connecting Claude to external services.

## What is MCP?

MCP allows Claude Code to directly query real-world tools — GitHub issues, Sentry errors, databases — without you having to copy-paste context manually. Claude can fetch live data during a session.

## Available Integrations

| Integration | Config File | What It Enables |
|------------|-------------|-----------------|
| GitHub | `github-config.json` | Read issues, PRs, code, create comments |
| Sentry | `sentry-config.json` | Query error events, stack traces, releases |

## Setup

### Step 1: Configure your secrets

Add the required values to `.env`:

```bash
# GitHub
GITHUB_TOKEN=ghp_your_token_here

# Sentry
SENTRY_TOKEN=your_sentry_auth_token
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
```

### Step 2: Merge MCP config into Claude settings

Add the MCP servers to `.claude/settings.json`. Merge `github-config.json` and/or `sentry-config.json` into the existing settings file:

```json
{
  "hooks": { ... },
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "sentry": {
      "command": "npx",
      "args": ["-y", "mcp-server-sentry"],
      "env": {
        "SENTRY_AUTH_TOKEN": "${SENTRY_TOKEN}",
        "SENTRY_ORG": "${SENTRY_ORG}",
        "SENTRY_PROJECT": "${SENTRY_PROJECT}"
      }
    }
  }
}
```

### Step 3: Verify

Restart Claude Code and verify MCP tools are available:
```
/mcp
```

You should see `github` and/or `sentry` listed as connected servers.

## GitHub MCP — What You Can Do

With GitHub MCP connected, Claude can directly:
- `list_issues` — fetch open issues with filters
- `get_issue` — read a specific issue's full content
- `create_pull_request` — open a PR from Claude
- `create_issue_comment` — post a review comment
- `search_code` — search the repo codebase

**Example prompt with GitHub MCP:**
> "Look at issue #42 and fix the bug described there."

Claude will fetch the issue directly — no manual copy-paste needed.

## Sentry MCP — What You Can Do

With Sentry MCP connected, Claude can:
- Fetch recent error events and stack traces
- Filter by project, environment, or time range
- Cross-reference Sentry errors with source code

**Example prompt with Sentry MCP:**
> "Check the latest Sentry errors in the production environment and fix the most frequent one."

## Security Notes

- `.env` is in `.gitignore` — never commit real tokens
- MCP servers run as child processes with only the env vars you provide
- The GitHub token only needs `repo` and `read:org` scopes for most operations
- Rotate tokens regularly and use fine-grained tokens when possible
