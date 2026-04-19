# MCP Integrations

MCP (Model Context Protocol) lets Claude directly query external services — GitHub, Sentry, databases — without copy-pasting context manually.

## Setup

See [mcp/README.md](../mcp/README.md) for detailed setup instructions.

**Quick version:**

1. Add tokens to `.env`
2. Merge MCP server config into `.claude/settings.json`
3. Restart Claude Code
4. Run `/mcp` to verify servers are connected

## GitHub Integration

**Config:** `mcp/github-config.json`
**Requires:** `GITHUB_TOKEN` with `repo` + `read:org` scopes

### What Claude can do with GitHub MCP

| Action | Description |
|--------|-------------|
| `list_issues` | Fetch open issues with filters (label, assignee, state) |
| `get_issue` | Read full issue body, comments, reactions |
| `create_pull_request` | Open a PR from a branch |
| `create_issue_comment` | Post a comment on an issue or PR |
| `get_pull_request` | Read PR metadata and diff |
| `search_code` | Search the repository's code |

### Example prompts

```
Look at issue #42 and fix the bug described there.
```
Claude fetches the issue directly — no copy-paste needed.

```
Review PR #15 and post a comment with your findings.
```
Claude reads the diff and posts a structured review comment.

```
What open issues are labeled "bug" in this repo?
```
Claude lists them with titles and descriptions.

## Sentry Integration  *(optional)*

**Default config:** `mcp/sentry-config.json` — Sentry's official remote MCP server
at `https://mcp.sentry.dev/mcp`, OAuth-authenticated.
**Requires (default path):** nothing in `.env`. OAuth happens on first `/mcp` call.

Add it with one command:

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

Then restart Claude Code, run `/mcp`, click the OAuth link, authorize.

> **The default path is for hosted Sentry only** (`sentry.io`). If you run a
> self-hosted Sentry, see [`mcp/README.md`](../mcp/README.md#sentry-mcp--self-hosted-advanced-optional)
> for the stdio-based alternative using `@sentry/mcp-server`.

> **Token vs DSN — read this if you've used Sentry SDKs before.** A DSN is a *write*
> credential used by SDKs that *send* errors to Sentry. The MCP integration is
> *read-only*: Claude queries your project's events. The default remote path uses
> OAuth, so neither a DSN nor a token is required. The self-hosted path uses a
> Sentry *user auth token* (`SENTRY_ACCESS_TOKEN`), which is also not a DSN.

### What Claude can do with Sentry MCP

| Action | Description |
|--------|-------------|
| List events | Fetch recent errors from Sentry |
| Get issue details | Full stack trace for a specific error |
| Filter by env | Production vs. staging errors |
| Search events | Find errors by query or tag |

### Example prompts

```
What are the top 5 errors in production this week?
```

```
Show me the full stack trace for Sentry issue PROJ-123 and find the source code causing it.
```

```
Are there any new errors since the last deploy?
```

## Creating Custom MCP Integrations

MCP servers can connect to any service with an API. Community servers exist for:
- PostgreSQL / SQLite databases
- Slack
- Linear
- Notion
- Filesystem tools

Find community MCP servers at [modelcontextprotocol.io](https://modelcontextprotocol.io).

**Generic config pattern:**
```json
{
  "mcpServers": {
    "my-service": {
      "command": "npx",
      "args": ["-y", "mcp-server-my-service"],
      "env": {
        "API_KEY": "${MY_SERVICE_API_KEY}"
      }
    }
  }
}
```

Add to `.claude/settings.json` under `"mcpServers"`.

## Security Considerations

- All MCP tokens live in `.env` (gitignored)
- MCP servers only receive the env vars you explicitly pass
- Use fine-grained tokens with minimum necessary scopes
- Rotate tokens if they're ever accidentally exposed
- Review what each MCP server can do before enabling it
