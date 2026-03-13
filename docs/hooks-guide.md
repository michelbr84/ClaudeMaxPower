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
