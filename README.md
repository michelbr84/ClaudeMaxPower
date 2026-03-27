# ClaudeMaxPower

**Turn Claude Code into a coordinated AI engineering team.**

ClaudeMaxPower is a GitHub template that transforms Claude from a solo assistant into a full
agent team — with hooks, skills, persistent memory, and Auto Dream memory consolidation.
It works in two modes:

- **New Project:** Install ClaudeMaxPower and it assembles a team (Architect + Implementer + Tester + Reviewer + Doc Writer) from day one
- **Existing Project:** Add ClaudeMaxPower and it creates a team tailored to your pending work, accelerating completion

Clone it, run `/assemble-team`, and watch Claude coordinate a team of specialized agents.

---

## Quick Start

```bash
# 1. Clone the template
git clone https://github.com/michelbr84/ClaudeMaxPower
cd ClaudeMaxPower

# 2. Run setup
bash scripts/setup.sh

# 3. Edit .env with your tokens
nano .env

# 4. Open Claude Code in this directory
claude

# 5. Try your first skill
/fix-issue --issue 1 --repo michelbr84/ClaudeMaxPower
```

---

## What's Inside

```
ClaudeMaxPower/
├── CLAUDE.md              ← Project-wide Claude instructions (layered)
├── .claude/
│   ├── settings.json      ← Hook config + Agent Teams enabled
│   ├── hooks/             ← Automated guards, quality gates, Auto Dream
│   └── agents/            ← Specialized sub-agents with persistent memory
├── skills/                ← Reusable AI workflows (invoke with /skill-name)
├── workflows/             ← Batch automation scripts
├── scripts/               ← Setup, verify, Auto Dream memory consolidation
├── mcp/                   ← MCP server configs (GitHub, Sentry)
├── examples/              ← Working demo projects
└── docs/                  ← Detailed guides for every feature
```

---

## Features

| Feature | What It Does |
|---------|-------------|
| **Agent Teams** | Assemble coordinated teams of specialized agents with `/assemble-team` |
| **Auto Dream** | Background memory consolidation — prunes stale entries, rebuilds index |
| **Layered CLAUDE.md** | Project-wide + subfolder-specific Claude instructions with `@imports` |
| **Hooks** | Auto-run tests after edits, block dangerous commands, save session state |
| **Skills** | Reusable `/fix-issue`, `/tdd-loop`, `/review-pr`, `/assemble-team`, and more |
| **Sub-Agents** | Specialized agents (code reviewer, security auditor, doc writer, team coordinator) |
| **Batch Workflows** | Fix multiple issues, mass-refactor, Writer/Reviewer pattern with worktrees |
| **MCP Integrations** | Claude reads GitHub issues and Sentry errors directly |
| **Example Projects** | Real code with intentional bugs to practice skills on |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Claude Code + ClaudeMaxPower             │
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │  CLAUDE.md    │  │    Hooks      │  │     Skills       │ │
│  │  (context)    │  │  (guardrails) │  │  (workflows)     │ │
│  └───────────────┘  └───────────────┘  └──────────────────┘ │
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │ Agent Teams   │  │  Workflows    │  │       MCP        │ │
│  │ (coordinator  │  │  (batch/      │  │  (GitHub/        │ │
│  │  + teammates) │  │  parallel)    │  │   Sentry)        │ │
│  └───────────────┘  └───────────────┘  └──────────────────┘ │
│                                                               │
│  ┌───────────────┐  ┌───────────────┐                        │
│  │  Auto Dream   │  │   Memory      │                        │
│  │  (consolidate │  │  (persistent  │                        │
│  │   memories)   │  │   context)    │                        │
│  └───────────────┘  └───────────────┘                        │
└──────────────────────────────────────────────────────────────┘
```

---

## Skills Reference

Invoke any skill with `/skill-name [arguments]` inside Claude Code.

| Skill | Command | Description |
|-------|---------|-------------|
| **Assemble Team** | `/assemble-team --mode new-project --description "..."` | Assemble an agent team tailored to your project |
| Fix Issue | `/fix-issue --issue 1 --repo owner/repo` | Read GitHub issue → write failing test → fix bug → open PR |
| Review PR | `/review-pr --pr 42 --repo owner/repo` | Full structured review → post comment via gh |
| Refactor Module | `/refactor-module --file src/foo.py --goal "extract validation"` | Safe refactor with test baseline |
| TDD Loop | `/tdd-loop --spec "add search feature" --file src/foo.py` | Write tests first, iterate until green |
| Pre-Commit | `/pre-commit` | Scan staged files for secrets, debug code, style issues |
| Generate Docs | `/generate-docs --dir src/` | Auto-generate API docs from source |

---

## Hooks

Hooks fire automatically — no prompting needed.

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `session-start.sh` | Session opens | Shows git context, previous session state, loaded skills |
| `pre-tool-use.sh` | Before any Bash command | Blocks dangerous commands, logs all commands to audit.log |
| `post-tool-use.sh` | After any file edit | Auto-runs tests for the modified file |
| `stop.sh` | Session ends | Saves session summary to `.estado.md` |

---

## Agents

Agents are invoked by Claude as sub-sessions with specialized roles.

| Agent | Memory | Role |
|-------|--------|------|
| `team-coordinator` | project | Orchestrates agent teams — spawns, coordinates, synthesizes |
| `code-reviewer` | project | Strict code review — correctness, security, tests |
| `security-auditor` | project | OWASP Top 10 scan, dependency audit, secret detection |
| `doc-writer` | user | Generates README, API docs, guides — adapts to your style |

---

## Workflow Scripts

```bash
# Fix multiple GitHub issues in sequence
./workflows/batch-fix.sh owner/repo 10 11 12

# Writer/Reviewer pattern with git worktrees
./workflows/parallel-review.sh --feature add-search --task "Add search_tasks() function"

# Refactor across all matching files
./workflows/mass-refactor.sh --pattern "get_user" --goal "rename to fetch_user"

# Generate dependency graph
./workflows/dependency-graph.sh --dir src/ --output docs/deps.svg
```

---

## Documentation

- [Getting Started](docs/getting-started.md) — prerequisites, setup, first run
- [Agent Teams Guide](docs/agent-teams-guide.md) — assembling and coordinating agent teams
- [Auto Dream Guide](docs/auto-dream-guide.md) — memory consolidation system
- [Hooks Guide](docs/hooks-guide.md) — how hooks work, how to customize them
- [Skills Guide](docs/skills-guide.md) — using and writing skills
- [Agents Guide](docs/agents-guide.md) — sub-agents and persistent memory
- [MCP Integrations](docs/mcp-integrations.md) — GitHub + Sentry setup
- [Batch Workflows](docs/batch-workflows.md) — headless automation patterns
- [Parallel Workflows](docs/worktrees-parallel.md) — Writer/Reviewer with worktrees
- [Troubleshooting](docs/troubleshooting.md) — common issues and fixes
- [14 Advanced Techniques](docs/techniques.md) — the techniques that inspired this project

---

## Who This Is For

- Solo developers who want to get dramatically more out of Claude Code
- Teams building repeatable AI-assisted engineering processes
- Claude Code power users exploring every advanced feature
- AI workflow builders looking for patterns to adapt

---

## License

MIT — see [LICENSE](LICENSE)

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Run `/pre-commit` before committing
4. Open a PR — the `review-pr` skill will help review it

Issues and ideas welcome at [GitHub Issues](https://github.com/michelbr84/ClaudeMaxPower/issues).
