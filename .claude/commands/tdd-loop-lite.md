---
description: Autonomous TDD loop — writes failing tests from a spec, then iterates on implementation until all tests are green. Stops at 10 iterations. Simpler TDD loop with 10-iteration cap — for use cases where the full strict TDD is overkill. For strict TDD with mandatory RED verification and iron-law enforcement, use /tdd-loop.
argument-hint: --spec <value> --file <value> [--test-file <value>]
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

Read `skills/tdd-loop-lite.md` in this repository and execute its workflow verbatim. Parse any arguments the user passed below and bind them to the skill's declared arguments before running.

User arguments: $ARGUMENTS
