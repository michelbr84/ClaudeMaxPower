# Hooks Guide

Hooks are shell scripts that Claude Code runs automatically at key moments — no prompting required.
They give you persistent guardrails, quality gates, and automation that work across every session.

## How Hooks Work

Hooks are configured in `.claude/settings.json` under the `"hooks"` key:

```json
{
  "hooks": {
    "SessionStart": [...],
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

Each hook entry specifies a shell command to run. The hook can:
- **Allow** the action by exiting with code 0
- **Block** the action by exiting with non-zero code (PreToolUse only)

## Available Hook Types

| Type | When It Fires | Can Block? |
|------|--------------|-----------|
| `SessionStart` | When a Claude session opens | No |
| `PreToolUse` | Before a tool runs | Yes |
| `PostToolUse` | After a tool completes | No |
| `Stop` | When a session ends | No |

## ClaudeMaxPower Hooks

### session-start.sh

**Fires:** When you open `claude` in this directory.

**What it does:**
1. Prints the current date/time
2. Shows current git branch and last 5 commits
3. Reads and displays `.estado.md` if it exists (previous session summary)
4. Warns if `.env` is missing or has unfilled placeholders
5. Lists all available skills

**Why it matters:** You never start a session blind. Claude always knows where the project is.

**Customize:** Edit `.claude/hooks/session-start.sh` to add project-specific checks.

---

### pre-tool-use.sh

**Fires:** Before every Bash tool execution.

**What it does:**
1. Logs every command to `.claude/audit.log` with a timestamp
2. **Blocks** commands matching dangerous patterns:
   - `rm -rf /` or `rm -rf ~`
   - Fork bombs (`:(){:|:&};:`)
   - Disk wipes (`dd if=/dev/zero`, `mkfs.`)
   - `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`
   - Force-pushes to `main` or `master`
3. **Warns** (but allows) on:
   - `pip install`, `npm install` (review before running)
   - `curl | bash` patterns

**Why it matters:** A single safety net catches the most catastrophic mistakes.

**Customize:** Edit `BLOCKED_PATTERNS` and `WARN_PATTERNS` arrays in the script.

> **Important:** This block-list is *defense in depth*, not the primary safety boundary.
> See [Hooks vs Claude Code's Sandbox](#hooks-vs-claude-codes-sandbox) for what it can
> and cannot catch.

---

### post-tool-use.sh

**Fires:** After every Edit or Write tool call.

**What it does:**
1. Detects the file extension of the modified file
2. For `.py` files: finds the nearest `tests/` directory and runs `pytest`
3. For `.js/.ts` files: finds the nearest `package.json` and runs `npm test`
4. Reports pass/fail back to Claude

**Why it matters:** Claude immediately knows if an edit broke tests — without you having to ask.

**Customize:** Add more file types or change the test command in the script.

---

### stop.sh

**Fires:** When the Claude session ends.

**What it does:**
1. Reads the session summary from `CLAUDE_STOP_HOOK_SUMMARY` environment variable
2. Prepends the summary to `.estado.md` (most recent first)
3. Stages `.estado.md` for git (but does not commit)

**Why it matters:** Session state persists across restarts. The next session's `session-start.sh` reads it.

---

## Audit Log

Every bash command Claude runs is logged to `.claude/audit.log`:

```
[2026-03-13 14:22:05] BASH: python -m pytest tests/ -v
[2026-03-13 14:22:11] BASH: git diff --staged
```

This log is in `.gitignore` — it's local only. Use it to review what Claude did in a session.

## Self-Test Your Hooks

ClaudeMaxPower ships a hook self-test you can run anytime:

```bash
bash scripts/test-hooks.sh
```

It runs each hook script with synthetic env vars in an isolated temporary
workspace and asserts the expected behaviour:

- `pre-tool-use.sh` allows benign commands and blocks `rm -rf /` and force-pushes to main
- `post-tool-use.sh` exits 0 when the file path is empty or non-source
- `stop.sh` writes a session entry to `.estado.md` (inside the tmp workspace, never your real one)
- `session-start.sh` runs cleanly even outside a git repository

A mutation guard at the end confirms `git status` is unchanged after the script
runs. If you customise a hook, re-run this script to verify your change still
respects the contract Claude Code expects.

> **What it does NOT verify:** whether Claude Code itself fires the hooks at the
> right moment. That requires running inside Claude Code with appropriate tracing.
> The self-test verifies the *scripts* are correct; firing is Claude Code's job.

## Hooks vs Claude Code's Sandbox

ClaudeMaxPower hooks are **defense in depth, not the primary safety boundary**. The
primary boundary is Claude Code itself — its per-tool permission prompts, its
permission mode, and any sandbox flags Claude Code exposes. Hooks are a thin
backstop that catches a handful of obviously catastrophic patterns; they do not
replace Claude Code's own enforcement.

### What each layer enforces

| Layer | Enforces | Examples |
|-------|----------|----------|
| **Claude Code (primary)** | Per-tool permission prompts; the active permission mode (`acceptEdits`, `auto`, `bypassPermissions`, `plan`); MCP server permissions; the harness's tool-call surface | Asks before running unfamiliar Bash commands; refuses unauthorized file writes in `plan` mode; mediates MCP tool access |
| **ClaudeMaxPower hooks (backstop)** | A small regex block-list in `pre-tool-use.sh`; auto-test on edit in `post-tool-use.sh`; session-state persistence in `stop.sh` | Blocks `rm -rf /`, force-pushes to `main`, fork bombs; runs pytest after every `.py` edit |

### What pre-tool-use.sh cannot catch

The `BLOCKED_PATTERNS` array in `pre-tool-use.sh` is regex-matched against the
literal command string passed to the `Bash` tool. By design, it cannot guarantee
enforcement against:

1. **Obfuscated commands.** Encoded payloads (`echo cm0gLXJmIC8K | base64 -d | sh`),
   indirection through environment variables (`X="rm -rf /"; $X`), commands sourced
   from disk (`sh ./hidden.sh`), or anything constructed at runtime can slip past
   a regex match.
2. **Dangerous behaviour via non-Bash tools.** The block-list runs only on the
   `Bash` tool. An `Edit` that overwrites a load-bearing config, a `Write` that
   deletes a file by replacing its contents with empty bytes, or a `WebFetch` that
   exfiltrates secrets is not seen by the block-list at all.
3. **Logic-level harm.** A correctly-formed `git push` to a wrong remote, a
   syntactically valid SQL migration that drops the wrong column, or a benign
   command run in a dangerous context — none of these match a syntactic pattern.

### Practical guidance

- **Respect Claude Code's permission prompts.** They are the primary boundary.
  Approving a tool call is an authorization decision; do not rely on the hook
  to second-guess it.
- **Prefer `plan` mode for risky work.** Plan mode prevents non-readonly tools
  from running until you exit plan mode explicitly. The hook block-list does
  not have an equivalent.
- **Treat the block-list as a backstop, not as authorization.** The fact that a
  command was *not blocked* does not mean it is safe; it only means it did not
  match a pattern.
- **Extend the block-list as you learn.** If a real incident exposes a new class
  of catastrophic command, add it to `BLOCKED_PATTERNS` so the next session is
  protected — but always alongside the higher-layer fix (revoking a permission,
  switching modes, fixing the workflow).

## Writing Your Own Hooks

Any shell script can be a hook. Tips:

1. **Always use `set -euo pipefail`** — fail fast and loud
2. **Exit 0 to allow, non-zero to block** (PreToolUse only)
3. **Write to stdout** — Claude Code shows hook output to the user
4. **Keep them fast** — hooks run on every matching event
5. **Idempotent** — the same hook may run multiple times

Example custom hook:
```bash
#!/usr/bin/env bash
# Post-tool-use: notify on Slack when a file is edited
set -euo pipefail
FILE="${CLAUDE_TOOL_OUTPUT_FILE_PATH:-}"
[ -z "$FILE" ] && exit 0
curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -d "{\"text\": \"Claude edited: $FILE\"}" > /dev/null
exit 0
```
