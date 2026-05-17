---
description: Use when user types /brainstorming, /writing-plans, /subagent-dev, /tdd-loop, /systematic-debugging, /using-worktrees, or /finish-branch — these moved to the Superpowers plugin. Routes the user to the canonical /superpowers:* command.
allowed-tools: Read
---

Read `skills/superpowers-redirect.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
