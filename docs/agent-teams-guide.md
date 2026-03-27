# Agent Teams Guide

Agent Teams allow Claude to spawn multiple specialized sub-agents that collaborate on a shared
task list. Instead of one agent doing everything sequentially, a team divides work by expertise
and executes in parallel — dramatically accelerating complex tasks.

## Enabling Agent Teams

Agent Teams require the experimental flag. ClaudeMaxPower enables this automatically in
`.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

You can also set it in your shell:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## How Agent Teams Work

1. **Coordinator** — The main Claude session acts as team lead. It creates a shared task list,
   spawns teammates, and synthesizes results.
2. **Teammates** — Specialized agents spawned via the `Agent` tool. Each gets a role, a subset
   of the task list, and appropriate tool permissions.
3. **Shared Task List** — All teammates read from and write to the same task list, enabling
   coordination without direct messaging.
4. **Synthesis** — The coordinator collects results, resolves conflicts, and delivers the
   final output.

## ClaudeMaxPower Team Patterns

### Pattern 1: New Project Supercharge

When starting a project from scratch, ClaudeMaxPower assembles a team that:

| Teammate | Role | What It Does |
|----------|------|-------------|
| **Architect** | Plan the structure | Analyzes requirements, proposes directory layout, defines modules |
| **Implementer** | Write the code | Builds out the codebase following the architect's plan |
| **Tester** | Write tests first | Creates test suites before or alongside implementation |
| **Reviewer** | Quality gate | Reviews each module for correctness, security, conventions |
| **Doc Writer** | Documentation | Generates README, API docs, inline docstrings |

Invoke with:
```
/assemble-team --mode new-project --description "A REST API for task management with auth"
```

### Pattern 2: Existing Project Acceleration

When adding ClaudeMaxPower to an existing project with pending work:

| Teammate | Role | What It Does |
|----------|------|-------------|
| **Analyst** | Understand the codebase | Maps architecture, finds patterns, identifies tech debt |
| **Planner** | Prioritize work | Reads issues/TODOs, creates ordered task list |
| **Implementer(s)** | Execute tasks | One or more agents working on independent tasks in parallel |
| **Reviewer** | Quality gate | Reviews each change against project conventions |
| **Tester** | Validate changes | Runs and writes tests for each completed task |

Invoke with:
```
/assemble-team --mode existing-project --goals "Fix issues #10 #11 #12 and add search feature"
```

## Team Communication

Teammates communicate through:

1. **Task list updates** — Each agent marks tasks as in_progress/completed and adds notes
2. **SendMessage** — Direct messages between named agents for coordination
3. **Shared files** — Agents read each other's output files (e.g., architecture docs, test results)

## Worktree Isolation

For teams where multiple agents edit code simultaneously, use git worktrees:

```
Agent(isolation: "worktree")
```

Each agent gets its own copy of the repo. Changes are merged back when complete. This prevents
conflicts between teammates editing different files.

## Writing Custom Team Compositions

You can describe any team structure in natural language:

```
Create an agent team with:
- A "researcher" that reads all source files and maps the dependency graph
- A "security-auditor" that scans for OWASP vulnerabilities
- A "performance-analyst" that identifies N+1 queries and expensive operations
- A "reporter" that synthesizes all findings into a single markdown report

The researcher should finish first, then the other three work in parallel,
and the reporter goes last.
```

Claude will create the team, set up dependencies, and coordinate execution.

## Best Practices

1. **Keep teams small** — 3-5 agents is ideal. More agents means more coordination overhead.
2. **Define clear boundaries** — Each agent should have a distinct, non-overlapping responsibility.
3. **Use dependencies** — Set `blockedBy` relationships so agents don't start before prerequisites.
4. **Restrict tools** — Give each agent only the tools it needs (principle of least privilege).
5. **Name your agents** — Use descriptive names so `SendMessage` is clear and logs are readable.
6. **Prefer worktrees for parallel edits** — Avoid merge conflicts by isolating file changes.
7. **Let the coordinator synthesize** — Don't have agents write final output; let the lead merge.

## Limitations

- Agent teams share a token budget — large teams on large codebases may hit context limits
- Teammates cannot spawn their own sub-teams (one level of nesting only)
- Worktree isolation requires a git repository
- Rate limits apply per-session — large teams may need delays between spawns
