# MCP Integrations

This directory contains MCP (Model Context Protocol) server configurations for connecting Claude to external services.

## What is MCP?

MCP allows Claude Code to directly query real-world tools — GitHub issues, Sentry errors, databases — without you having to copy-paste context manually. Claude can fetch live data during a session.

## Available Integrations

| Integration | Config File | Required? | What It Enables |
|------------|-------------|-----------|-----------------|
| GitHub | `github-config.json` | Recommended | Read issues, PRs, code, create comments |
| Sentry | `sentry-config.json` | **Optional** | Query error events, stack traces, releases |

> **Sentry is opt-in.** Nothing in this template initializes the Sentry SDK or sends
> errors to Sentry from your machine. The Sentry MCP server is a one-way data path —
> *Claude reads from your Sentry project*, nothing in the template writes to it.

## Setup

### Step 1: Configure your secrets

Add the required values to `.env` (create from `.env.example` if you haven't already):

```bash
# GitHub  (recommended)
GITHUB_TOKEN=ghp_your_token_here

# Sentry  (optional — only needed if you enable the Sentry MCP server below)
SENTRY_TOKEN=your_sentry_auth_token   # Sentry auth token, NOT a DSN
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
```

**About `SENTRY_TOKEN`:** this is a Sentry *auth token* (management API credential)
— not a DSN. DSNs are for SDKs that *send* errors; this template doesn't ship an
SDK. Create an auth token at
[sentry.io/settings/account/api/auth-tokens/](https://sentry.io/settings/account/api/auth-tokens/)
with scopes `project:read`, `event:read`, `org:read`. Use a fine-grained token
scoped to the single project you want Claude to see.

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

### Sentry MCP — What this is NOT

This integration is the **Claude → Sentry read path**. It is not an error reporter.

- It does **not** initialize the Sentry SDK in your project.
- It does **not** send errors from this template (or its example app) to Sentry.
- It does **not** require a DSN.

If you also want runtime error reporting from your own app, install and configure
the appropriate Sentry SDK in *that* application — not in the template root. Read
the DSN from `os.environ["SENTRY_DSN"]` (or the framework equivalent), keep init
conditional on the env var being set, and never commit a DSN to source.

## Security Notes

- `.env` is in `.gitignore` — never commit real tokens
- MCP servers run as child processes with only the env vars you provide
- The GitHub token only needs `repo` and `read:org` scopes for most operations
- Use fine-grained tokens (project-scoped for Sentry, repo-scoped for GitHub) when possible
- Rotate tokens regularly
- **Sentry: token, not DSN.** A DSN identifies a project for *write* access (sending
  errors). The MCP server uses an *auth token* for *read* access. Don't paste your DSN
  into `SENTRY_TOKEN` — it won't work and it's a different secret with different
  rotation requirements.
- **`npx -y` always pulls the latest version** of an MCP server package on each launch.
  That's convenient but means upstream updates are applied without review. For
  production use, pin a specific version (`npx -y mcp-server-sentry@<version>`) or
  install the package globally and reference it by absolute path.
