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

### Step 1: Configure GitHub credentials

Add to `.env` (create from `.env.example` if you haven't already):

```bash
GITHUB_TOKEN=ghp_your_token_here
```

The Sentry default path uses OAuth — no env vars needed.

### Step 2: Add MCP servers to Claude Code

The fastest path is the `claude mcp add` CLI:

```bash
# GitHub (stdio, npm package, token auth)
claude mcp add --transport stdio github \
  --env GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN \
  -- npx -y @modelcontextprotocol/server-github

# Sentry (remote, OAuth — official Sentry-hosted endpoint)
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

Or merge the JSON snippets from `github-config.json` and `sentry-config.json`
into your `.claude/settings.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

### Step 3: Verify and authenticate

Restart Claude Code and run:
```
/mcp
```

`github` should connect immediately using your token. `sentry` will appear with
a link to authenticate via OAuth in your browser — click it, log in to Sentry,
authorize the connection. Subsequent sessions reuse the OAuth token automatically.

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

The org and project to query are supplied per-prompt — there are no `SENTRY_ORG`
or `SENTRY_PROJECT` env vars in the default path. Claude infers them from your
OAuth-authorized scope plus what you mention in the prompt.

### Sentry MCP — What this is NOT

This integration is the **Claude → Sentry read path**. It is not an error reporter.

- It does **not** initialize the Sentry SDK in your project.
- It does **not** send errors from this template (or its example app) to Sentry.
- It does **not** require a DSN.

If you also want runtime error reporting from your own app, install and configure
the appropriate Sentry SDK in *that* application — not in the template root. Read
the DSN from `os.environ["SENTRY_DSN"]` (or the framework equivalent), keep init
conditional on the env var being set, and never commit a DSN to source.

### Sentry MCP — Self-hosted (advanced, optional)

If you run a self-hosted Sentry instance, the remote OAuth endpoint
(`mcp.sentry.dev`) won't reach it. Switch to the official **stdio** server,
which runs locally and talks to your Sentry over HTTPS:

1. In `.env`, set:
   ```bash
   SENTRY_ACCESS_TOKEN=<your self-hosted Sentry user auth token>
   SENTRY_HOST=https://sentry.example.com
   ```
   Required token scopes: `org:read`, `project:read`, `project:write`,
   `team:read`, `team:write`, `event:write`. Note these are *broader* than
   read-only — review whether that's acceptable for your environment.

2. Replace the `sentry` block in `.claude/settings.json` with the stdio shape:
   ```json
   {
     "mcpServers": {
       "sentry": {
         "command": "npx",
         "args": ["-y", "@sentry/mcp-server@0.32.0"],
         "env": {
           "SENTRY_ACCESS_TOKEN": "${SENTRY_ACCESS_TOKEN}",
           "SENTRY_HOST": "${SENTRY_HOST}"
         }
       }
     }
   }
   ```
   `@sentry/mcp-server` is the official Sentry-maintained npm package
   ([getsentry/sentry-mcp](https://github.com/getsentry/sentry-mcp)). Pin a
   specific version (the example uses `0.32.0`) rather than `@latest` for
   reproducible installs.

3. Restart Claude Code and run `/mcp` to verify.

This path is unrelated to OAuth — auth is done via the access token.

## Security Notes

- `.env` is in `.gitignore` — never commit real tokens
- MCP servers run as child processes (stdio) or make network calls (http/sse) with
  only the credentials you explicitly provide
- The GitHub token only needs `repo` and `read:org` scopes for most operations
- Use fine-grained tokens (repo-scoped for GitHub, project-scoped for self-hosted
  Sentry) when possible; rotate them regularly
- **Sentry default path (remote OAuth):** no long-lived secret lives in `.env`.
  The OAuth token is stored by Claude Code and can be revoked from
  [sentry.io/settings/account/api/authorized-applications/](https://sentry.io/settings/account/api/authorized-applications/)
- **Sentry self-hosted path:** `SENTRY_ACCESS_TOKEN` is a Sentry *user auth token*,
  not a DSN. A DSN is a write credential used by SDKs that *send* errors. Don't
  paste a DSN here — it won't authenticate.
- **`npx -y` always pulls the latest version** of an npm MCP server package. For
  self-hosted Sentry and for GitHub, pin a specific version
  (`@sentry/mcp-server@0.32.0`, `@modelcontextprotocol/server-github@<version>`)
  rather than relying on `latest`.
