---
description: Break an approved spec into bite-sized, subagent-executable implementation tasks
argument-hint: --spec <value> [--output <value>]
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, TaskCreate, TaskUpdate
---

Read `skills/writing-plans.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
