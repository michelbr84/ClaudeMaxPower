# Getting Started with ClaudeMaxPower

## Prerequisites

Before starting, install these tools:

| Tool | Install | Why |
|------|---------|-----|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | The AI CLI |
| Git | [git-scm.com](https://git-scm.com) | Version control |
| GitHub CLI | `brew install gh` or [cli.github.com](https://cli.github.com) | PR and issue integration |
| jq | `brew install jq` or `apt install jq` | JSON parsing in scripts |
| Python 3.10+ | [python.org](https://python.org) | Example projects |

## Setup

### 1. Clone the template

```bash
git clone https://github.com/your-username/ClaudeMaxPower
cd ClaudeMaxPower
```

### 2. Run the setup script

```bash
bash scripts/setup.sh
```

This will:
- Check all required tools are installed
- Create `.env` from `.env.example`
- Make hook and workflow scripts executable
- Install Python dependencies for examples
- Check GitHub CLI authentication

### 3. Configure your tokens

Edit `.env` with your actual values:

```bash
nano .env
```

Required for full functionality:
- `GITHUB_TOKEN` — from [github.com/settings/tokens](https://github.com/settings/tokens)
  - Scopes: `repo`, `read:org`
- `DEFAULT_REPO` — your default repository in `owner/repo` format

Optional:
- The Sentry MCP integration (Claude reads your Sentry errors during a session)
  uses the official remote OAuth endpoint by default and needs **no env vars** —
  authentication is handled by Claude Code on first `/mcp` call. If you run
  self-hosted Sentry, see [`mcp/README.md`](../mcp/README.md#sentry-mcp--self-hosted-advanced-optional)
  for the stdio-based alternative and the env vars it needs
  (`SENTRY_ACCESS_TOKEN`, `SENTRY_HOST`).

### 4. Verify everything is working

```bash
bash scripts/verify.sh
```

All checks should pass (or warn for optional tools).

### 5. Open Claude Code

```bash
claude
```

You should see the session-start hook fire, showing your git context and available skills.

## First Steps

### Activate maximum capability

```bash
# Inside Claude Code:
/max-power
```

This detects your environment, runs setup, offers to install the optional Superpowers plugin,
and routes you to the right skill for your goal. It's the recommended first command for every
new project.

### Try the pipeline on a feature

```bash
# 1. Brainstorm the design (hard gate: produces an approved spec)
/brainstorming --topic "task search"

# 2. Break the spec into bite-sized tasks
/writing-plans --spec docs/specs/2026-04-17-task-search-design.md

# 3. Execute with fresh subagents + two-stage review
/subagent-dev --plan docs/plans/2026-04-17-task-search-plan.md

# 4. Finish: merge, PR, or keep
/finish-branch
```

### Or try a single-purpose skill

```bash
/pre-commit
```

This runs a pre-commit check on your staged files. Since you're in a fresh clone with nothing staged, it will tell you nothing is staged — that's correct.

### Run the example tests

The todo-app has intentional bugs to demonstrate skills:

```bash
python -m pytest examples/todo-app/tests/ -v
```

You'll see 3 tests fail — those are the bugs the `fix-issue` skill is designed to fix.

### Explore the structure

```bash
ls -la .claude/hooks/     # Hooks
ls skills/                # Skills
ls .claude/agents/        # Agents
ls workflows/             # Batch scripts
```

## What to Read Next

- [Superpowers Integration](superpowers-integration.md) — the merged pipeline and decision tables
- [Bootstrap Prompt](bootstrap-prompt.md) — copy-paste activator for any Claude session
- [Hooks Guide](hooks-guide.md) — understand what fires automatically
- [Skills Guide](skills-guide.md) — learn to use and write skills
- [Agents Guide](agents-guide.md) — specialized sub-agents
