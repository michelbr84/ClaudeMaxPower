---
description: Execute a plan with a fresh subagent per task and two-stage review (spec then quality)
argument-hint: --plan <value> [--worktree <value>]
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Agent, TaskCreate, TaskUpdate
---

Read `skills/subagent-dev.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
