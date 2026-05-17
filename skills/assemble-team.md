---
name: assemble-team
description: Analyze a project and assemble an optimal agent team — enforces brainstorming/spec gate before implementation for new-project mode.
arguments:
  - name: mode
    description: "new-project or existing-project"
    required: true
  - name: description
    description: "Project description (for new-project mode)"
    required: false
  - name: goals
    description: "Goals or pending items to accomplish (for existing-project mode)"
    required: false
  - name: team-size
    description: "Max number of teammates (default: 5)"
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
---

# Skill: assemble-team

Assemble an agent team optimized for the user's project and goals. This is ClaudeMaxPower's
core superpower — it turns Claude from a solo assistant into a coordinated engineering team.

## Workflow

### Step 0: Brainstorming gate (spec check)

**No implementation until spec is approved — this is the same hard gate enforced by `/superpowers:brainstorming`.**

Before analyzing the project or composing any team, verify that the work has been scoped.

**For `new-project` mode:** a design spec MUST exist under `docs/specs/`. If none exists, stop and instruct the user to run `/superpowers:brainstorming <feature>` first (install the Superpowers plugin with `/plugin install superpowers@claude-plugins-official` if not already installed). This is a hard gate — do not proceed, do not spawn agents, do not plan tasks.

```bash
ls docs/specs/*-design.md 2>/dev/null
```

- If the command returns one or more files, read the most recent design spec and use it as the source of truth for Step 2 onwards.
- If the command returns nothing, respond to the user with:

  > No design spec found in `docs/specs/`. Run `/superpowers:brainstorming <feature>` first to produce an approved spec, then re-run `/assemble-team`. (Install the Superpowers plugin with `/plugin install superpowers@claude-plugins-official` if it isn't already installed.)

  Then stop. Do not continue to Step 1.

**For `existing-project` mode:** check for pending specs and evaluate goal concreteness.

```bash
ls docs/specs/*-design.md 2>/dev/null
```

- If `--goals` is vague (e.g. "improve the app", "make it better", "modernize", "clean up"), **stop and ask the user explicitly**:

  > Goals are too high-level for team assembly. The right next step is
  > `/superpowers:brainstorming` to sharpen intent into concrete tasks. Continue with
  > exploratory analysis anyway? (yes/no — default no)

  Treat any answer other than an explicit "yes" as no, and stop. Do not silently fall
  through to the team build.
- If `--goals` is concrete — references GitHub issues (`#10 #11 #12`), specific file TODOs, named features, or points to an existing spec in `docs/specs/` — proceed to Step 1.
- If specs exist in `docs/specs/`, read them and use them alongside `--goals` when designing the team.

State clearly in the chat: "No implementation until spec is approved — this is the same hard gate enforced by /superpowers:brainstorming."

### Step 1: Determine mode and validate inputs

```
MODE = $mode (required: "new-project" or "existing-project")
DESCRIPTION = $description (required if new-project)
GOALS = $goals (required if existing-project)
TEAM_SIZE = $team-size (default: 5, max: 7)
```

If mode is missing or invalid, ask the user.

### Step 2: Analyze the project context

**For new-project mode:**
1. Parse the project description to identify:
   - Primary language/framework
   - Key features and modules
   - External integrations (APIs, databases, auth)
   - Testing requirements
   - Documentation needs
2. Design the project structure (directories, key files, config)

**For existing-project mode:**
1. Read the project root: `CLAUDE.md`, `README.md`, `package.json` or `requirements.txt`
2. Map the directory structure with `Glob("**/*")`
3. Identify the tech stack (languages, frameworks, test runner)
4. Parse the goals:
   - If goals reference GitHub issues, fetch them with `gh issue view`
   - If goals are free-text, break them into discrete tasks
   - If goals mention "pending items", scan for `TODO`, `FIXME`, `HACK` in source code
5. Identify dependencies between tasks

### Step 3: Design the team composition

Read `skills/references/team-roster.md` for the full role catalogue (Architect,
Implementer, Tester, Reviewer, Doc Writer, Analyst, Security Auditor, DevOps), the
composition rules, the spawn order, and the task-dependency policy. Select teammates from
that roster based on your Step 2 analysis. The roster lives in a reference file so it can
evolve without churning this skill body.

### Step 4: Create the shared task list

Create tasks using `TaskCreate` for each work item. Apply the dependency rules from
`skills/references/team-roster.md` (Task dependencies section).

Each task must have:
- Clear subject (imperative form)
- Description with acceptance criteria
- Owner (teammate name)

### Step 5: Spawn the team

For each teammate, use the `Agent` tool:

```
Agent(
  name: "<role-name>",
  subagent_type: "general-purpose",
  prompt: "<role-specific prompt with context and assigned tasks>",
  isolation: "worktree"  // only for agents that edit files
)
```

**Spawn order:** see "Spawn order" in `skills/references/team-roster.md`. For the second
wave, spawn all agents in a single message (parallel execution).

**Execution strategy option:** For teams where tasks are mostly independent, consider using
`/superpowers:subagent-driven-development` as the execution backbone instead of spawning all
teammates upfront. This gives you fresh-context subagents per task with two-stage review
(spec compliance then code quality). Use `/superpowers:writing-plans` to produce the plan
file, then `/superpowers:subagent-driven-development --plan <file>`.

### Step 6: Coordinate and synthesize

As teammates complete:
1. Check their output and task status
2. If a reviewer finds issues, create fix tasks and assign to implementer
3. When all tasks are complete, synthesize a summary report

### Step 7: Report results

Output a structured summary:

```markdown
## Team Assembly Report

**Mode:** new-project / existing-project
**Team Size:** N teammates
**Tasks:** X completed / Y total

### Team Composition
| Teammate | Role | Tasks Assigned | Status |
|----------|------|---------------|--------|

### Completed Work
- [list of what was accomplished]

### Review Findings
- [any issues found and resolved]

### Next Steps
- [remaining work or recommendations]
```

**Feedback:** Did `/assemble-team` produce the right composition for your work? Reply with
a 1–10 rating, what slowed you down, or a faster path from where you started to where you
ended.

## Error Handling

- If a teammate fails, log the error and reassign the task to the coordinator
- If tests fail after implementation, create a fix task (do not skip tests)
- If the team exceeds context limits, reduce team size and serialize work
- If a worktree merge conflicts, the coordinator resolves manually

## Examples

**New project:**
```
/assemble-team --mode new-project --description "Python CLI tool for managing Docker containers with health checks, auto-restart, and Slack notifications"
```

**Existing project with issues:**
```
/assemble-team --mode existing-project --goals "Fix GitHub issues #10 #11 #12, add pagination to the API, and improve test coverage to 80%"
```

**Existing project with TODOs:**
```
/assemble-team --mode existing-project --goals "Complete all TODO and FIXME items in src/"
```

## Related skills

- `/superpowers:brainstorming` — Step 0 gate. Produces the approved design spec in `docs/specs/` that this skill consumes. Required for `new-project` mode; recommended when `existing-project` goals are vague.
- `/superpowers:writing-plans` — Turns an approved spec into a concrete task breakdown plan file. Pair with `/superpowers:subagent-driven-development` for the alternate execution path.
- `/superpowers:subagent-driven-development` — Alternate execution backbone. Runs tasks through fresh-context subagents with two-stage review. Preferred when tasks are largely independent.
- `/superpowers:finishing-a-development-branch` — Post-completion workflow. Once the team has finished and all checks pass, use this to merge, open a PR, or clean up the development branch.
