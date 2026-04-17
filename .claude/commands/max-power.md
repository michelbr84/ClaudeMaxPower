---
description: One-command activation — installs ClaudeMaxPower, offers Superpowers plugin install, presents capabilities menu, and routes the user to the right skill for their immediate goal.
argument-hint: [--goal <value>] [--mode <value>] [--install-superpowers-plugin <value>]
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Agent, TaskCreate, TaskUpdate
---

Read `skills/max-power.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
