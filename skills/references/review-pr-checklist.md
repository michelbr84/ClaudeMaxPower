# PR Review Checklist Reference

Used by `/review-pr`. Read this in Step 3 before composing the structured review.

## Correctness

- Logic errors or edge cases not handled?
- Off-by-one errors, null dereferences, race conditions?
- Error cases handled (not just happy path)?
- New code paths exercised by at least one test?
- Concurrency: shared state mutated without synchronization?

## Security (OWASP Top 10 basics)

- Any SQL built via string concatenation (SQL injection risk)?
- User input rendered directly in output (XSS risk)?
- Secrets, credentials, or tokens in code, comments, or fixtures?
- New dependencies introduced? Trusted sources, pinned versions, no obvious typo-squats?
- Authorization: new endpoints/routes properly gated?
- Cryptography: any hand-rolled hashing or weak algorithms (MD5, SHA-1)?

## Tests

- Are new features covered by tests?
- Are bug fixes accompanied by a regression test that fails on the old code?
- Do the tests actually test what they claim (not just exercising code paths)?
- Are mocks used where real implementations would be safer?

## Style and maintainability

- Consistent with project conventions (`CLAUDE.md`)?
- Function/variable names clear and descriptive?
- Any obvious code duplication that could be extracted?
- Comments explain *why*, not *what*?
- Public API additions have docstrings/JSDoc?

## Breaking changes

- Does this change any public APIs or interfaces?
- Are all callers updated?
- Is there a migration path or compatibility shim?
- Database/schema migrations: reversible? Backfill plan?

## Operational

- New environment variables documented?
- New external dependencies (services, queues, caches) configured for all envs?
- Logs/metrics for any new code path that could fail in production?
- Feature flag gating if applicable?
