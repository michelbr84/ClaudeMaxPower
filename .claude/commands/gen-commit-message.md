---
description: Use when user has staged changes and asks for a commit message, says "what should the commit message be", or types /gen-commit-message. Reads `git diff --staged` and proposes a Conventional Commits message (feat/fix/docs/refactor/test/chore).
allowed-tools: Bash, Read
---

Read `skills/gen-commit-message.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
