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

The pipeline skills live upstream in the Superpowers plugin. Install once with
`/plugin install superpowers@claude-plugins-official`, then:

```bash
# 1. Brainstorm the design (hard gate: produces an approved spec)
/superpowers:brainstorming "task search"

# 2. Break the spec into bite-sized tasks
/superpowers:writing-plans docs/specs/2026-04-17-task-search-design.md

# 3. Execute with fresh subagents + two-stage review
/superpowers:subagent-driven-development docs/plans/2026-04-17-task-search-plan.md

# 4. Finish: merge, PR, or keep
/superpowers:finishing-a-development-branch
```

If you forget the prefix and type the legacy unqualified name (`/brainstorming`,
`/tdd-loop`, etc.) the `/superpowers-redirect` skill catches it and tells you the
canonical command.

### Or try a single-purpose skill

```bash
/gen-commit-message
```

This reads `git diff --staged` and proposes a Conventional Commits message. Since you're
in a fresh clone with nothing staged, it will tell you nothing is staged — that's correct.

(The deterministic pre-commit checks — secrets, debug statements, large files, linter — run
automatically via the `pre-commit-check.sh` hook on every `git commit`; no skill invocation
needed.)

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
