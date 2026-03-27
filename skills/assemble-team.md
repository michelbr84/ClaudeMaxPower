---
name: assemble-team
description: Analyze a project and assemble an optimal agent team tailored to the user's goals
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

Based on the analysis, select teammates from this roster:

| Role | Best For | Tools |
|------|----------|-------|
| **Architect** | Designing structure, API contracts, module boundaries | Read, Glob, Grep, Write |
| **Implementer** | Writing production code | Read, Edit, Write, Bash, Glob, Grep |
| **Tester** | Writing and running tests (TDD-first) | Read, Edit, Write, Bash, Glob, Grep |
| **Reviewer** | Code review, catching bugs and security issues | Read, Glob, Grep |
| **Doc Writer** | README, API docs, inline documentation | Read, Edit, Write, Glob, Grep |
| **Analyst** | Codebase mapping, dependency analysis, tech debt | Read, Glob, Grep, Bash |
| **Security Auditor** | OWASP scanning, credential checks, dependency audit | Read, Glob, Grep, Bash |
| **DevOps** | CI/CD, Docker, deployment configs | Read, Edit, Write, Bash, Glob, Grep |

Rules:
- Always include a **Reviewer** — no code ships without review
- For new-project: always include **Architect** + **Implementer** + **Tester**
- For existing-project: always include **Analyst** first (it must finish before others start)
- Respect TEAM_SIZE limit — combine roles if needed (e.g., Tester+Reviewer)

### Step 4: Create the shared task list

Create tasks using `TaskCreate` for each work item. Set dependencies:
- Architect tasks block Implementer tasks
- Analyst tasks block all other tasks (existing-project mode)
- Implementer tasks block Reviewer tasks
- All code tasks block Doc Writer tasks

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

**Spawn order:**
1. First wave: Architect or Analyst (must complete before others)
2. Second wave: Implementers + Testers (can run in parallel)
3. Third wave: Reviewer (after code is written)
4. Fourth wave: Doc Writer (after review passes)

For the second wave, spawn all agents in a single message (parallel execution).

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
