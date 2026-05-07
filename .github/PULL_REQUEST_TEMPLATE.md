<!--
Thanks for opening a PR. Please fill in the sections below.

Trivial changes (typos, obvious one-liners, formatting) can keep this short.
For non-trivial changes, please link the spec, the plan, and the related issue.

See CONTRIBUTING.md for the full pipeline (brainstorming -> writing-plans ->
subagent-dev -> finish-branch) and the four iron laws.
-->

## Summary

<!-- What changed and why, in 1-3 sentences. Focus on the "why". -->

## Related issues / specs / plans

<!--
- Closes #N
- Spec: docs/specs/YYYY-MM-DD-<topic>-design.md
- Plan: docs/plans/YYYY-MM-DD-<topic>-plan.md
- Linear: PROJ-123 (if applicable)
-->

## Type of change

<!-- Check one. -->

- [ ] feat (new user-visible feature)
- [ ] fix (bug fix)
- [ ] docs (documentation only)
- [ ] chore (tooling, config, hygiene)
- [ ] ci (CI / workflow changes)
- [ ] refactor (no behavior change)
- [ ] test (test-only)

## Test plan

<!--
What did you run? What did you observe?
Include the exact commands so a reviewer can reproduce.

- [ ] `pytest examples/todo-app/tests/`  (if Python touched)
- [ ] `bash scripts/test-hooks.sh`        (if hooks touched)
- [ ] `bash scripts/validate-skills.sh`   (if skills touched)
- [ ] `shellcheck <files>`                (if shell scripts touched)
-->

## Iron-law checklist

<!-- See CLAUDE.md and docs/superpowers-integration.md. -->

- [ ] Tests cover the new behavior (or a documented exception applies).
- [ ] No production code merged without a failing test first.
- [ ] If this is a bug fix, the root cause is identified in the PR body —
      not just the symptom.
- [ ] CI is green on this branch.

## Hygiene checklist

- [ ] Conventional Commits message style.
- [ ] No `.env` or other secrets committed.
- [ ] No `--no-verify` or hook bypasses.
- [ ] No force-push, no history rewrite on pushed branches.
- [ ] No weakening of branch protection, required checks, or security settings.
- [ ] If this adapts content from another MIT project, attribution is in
      `ATTRIBUTION.md`.

## Notes for the reviewer

<!--
Anything the reviewer should know? Trade-offs you considered, alternatives
you ruled out, follow-ups you'll handle in another PR.
-->
