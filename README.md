# ClaudeMaxPower

**Turn Claude Code into a coordinated AI engineering team — with the full Superpowers methodology built in.**

ClaudeMaxPower is a GitHub template that transforms Claude from a solo assistant into a full
AI engineering team — with hooks, skills, persistent memory, Auto Dream memory consolidation,
and an integrated adaptation of the obra/superpowers methodology (brainstorm → spec → plan →
subagent-driven development with strict TDD → two-stage review → finish).

It works in two modes:

- **New Project:** Install ClaudeMaxPower, brainstorm a feature, assemble a team, and ship
- **Existing Project:** Add ClaudeMaxPower and it creates a team tailored to your pending work

Clone it, run `/max-power`, and watch Claude operate at maximum capability.

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

# 5. Activate maximum capability
/max-power

# Or jump straight to your goal:
/brainstorming --topic "new feature"
/fix-issue --issue 1 --repo michelbr84/ClaudeMaxPower
/assemble-team --mode new-project --description "REST API for task management"
```

### Already in a Claude session? Use the bootstrap prompt

Copy the prompt from [`docs/bootstrap-prompt.md`](docs/bootstrap-prompt.md) into any Claude
Code (or Cursor, Codex, Gemini) session — it will clone ClaudeMaxPower, install the
optional Superpowers plugin, run setup, and present the pipeline menu.

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
| **Superpowers Pipeline** | Brainstorm → spec → plan → subagent-driven dev → two-stage review → finish |
| **One-Command Bootstrap** | `/max-power` installs, configures, and routes you to the right skill |
| **Agent Teams** | Assemble coordinated teams of specialized agents with `/assemble-team` |
| **Auto Dream** | Background memory consolidation — prunes stale entries, rebuilds index |
| **Layered CLAUDE.md** | Project-wide + subfolder-specific Claude instructions with `@imports` |
| **Hooks** | Auto-run tests after edits, block dangerous commands, save session state |
| **Strict TDD** | Iron-law TDD (`/tdd-loop`) plus lite option (`/tdd-loop-lite`) for flexibility |
| **Systematic Debugging** | 4-phase root-cause process — never patch a symptom |
| **Git Worktree Isolation** | Safe parallel development with `/using-worktrees` and `/finish-branch` |
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

## Superpowers Integration

ClaudeMaxPower integrates the [obra/superpowers](https://github.com/obra/superpowers) (MIT)
methodology directly as inlined skills. You get the full pipeline without a submodule or
plugin dependency. See [`docs/superpowers-integration.md`](docs/superpowers-integration.md)
for the merged pipeline, decision tables, and migration notes.

**Four Iron Laws** enforced by the skills:

1. No production code without a failing test first (`/tdd-loop`)
2. No implementation without an approved spec (`/brainstorming` hard gate)
3. No fixes without root-cause investigation (`/systematic-debugging`)
4. No merging with failing tests (`/finish-branch` verification)

Attribution: see [`ATTRIBUTION.md`](ATTRIBUTION.md).

---

## Skills Reference

Invoke any skill with `/skill-name [arguments]` inside Claude Code.

**Pipeline skills (Superpowers methodology):**

| Skill | Command | Description |
|-------|---------|-------------|
| Brainstorming | `/brainstorming --topic "user-auth"` | Collaborative design → spec (hard gate) |
| Writing Plans | `/writing-plans --spec docs/specs/...md` | Break spec into bite-sized tasks |
| Subagent Dev | `/subagent-dev --plan docs/plans/...md` | Fresh subagent per task + two-stage review |
| Systematic Debugging | `/systematic-debugging --issue "..."` | 4-phase root-cause process |
| Finish Branch | `/finish-branch` | Merge / PR / keep / discard + worktree cleanup |
| Using Worktrees | `/using-worktrees --branch feat/xxx` | Safe isolated git worktree |
| TDD Loop | `/tdd-loop --spec "..." --file path` | Strict Red-Green-Refactor with iron law |
| TDD Loop (Lite) | `/tdd-loop-lite --spec "..." --file path` | Simpler TDD loop (pre-integration version) |

**ClaudeMaxPower native skills:**

| Skill | Command | Description |
|-------|---------|-------------|
| **Max Power** | `/max-power` | One-command activation — installs, configures, routes |
| **Assemble Team** | `/assemble-team --mode new-project --description "..."` | Assemble an agent team (brainstorming gate enforced) |
| Fix Issue | `/fix-issue --issue 1 --repo owner/repo` | Read issue → failing test → fix → PR |
| Review PR | `/review-pr --pr 42 --repo owner/repo` | Structured review → post comment via gh |
| Refactor Module | `/refactor-module --file src/foo.py --goal "..."` | Safe refactor with test baseline |
| Pre-Commit | `/pre-commit` | Scan staged files for secrets, debug code, style |
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
- **[Superpowers Integration](docs/superpowers-integration.md)** — merged pipeline, decision tables
- **[Bootstrap Prompt](docs/bootstrap-prompt.md)** — copy-paste activation for any Claude session
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
- [ATTRIBUTION](ATTRIBUTION.md) — MIT credits for adapted content

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
