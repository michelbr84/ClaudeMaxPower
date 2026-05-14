# Team Roster Reference

Used by `/assemble-team`. Read this when composing a team in Step 3.

## Available roles

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

## Composition rules

- Always include a **Reviewer** — no code ships without review.
- For `new-project`: always include **Architect** + **Implementer** + **Tester**.
- For `existing-project`: always include **Analyst** first (it must finish before others start).
- Respect the `--team-size` limit (default 5, max 7) — combine roles if needed (e.g., Tester+Reviewer).

## Spawn order

1. **First wave**: Architect or Analyst (must complete before others).
2. **Second wave**: Implementers + Testers (parallel, single message with multiple Agent calls).
3. **Third wave**: Reviewer (after code is written).
4. **Fourth wave**: Doc Writer (after review passes).

## Task dependencies (set when calling TaskCreate / TaskUpdate)

- Architect tasks block Implementer tasks.
- Analyst tasks block all other tasks (existing-project mode).
- Implementer tasks block Reviewer tasks.
- All code tasks block Doc Writer tasks.
