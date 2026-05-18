# 30 — Git, GitHub, and CI

Branch policy, PR policy, commit message format, and CI expectations. Test-discipline rules
that touch git workflow are owned by [10-iron-laws.md](10-iron-laws.md); secret hygiene at
commit time is owned by [60-security-privacy.md](60-security-privacy.md).

## Branch Policy

- **Never push to `main` or `master` directly.** Always use a feature branch + PR. This is
  one of the Absolute Rules registered in [10-iron-laws.md](10-iron-laws.md).
- The hook `.claude/hooks/pre-tool-use.sh` blocks force-pushes to `main` or `master` as a
  backstop — see [`../docs/hooks-guide.md`](../docs/hooks-guide.md).

## Commit Messages

- Use **Conventional Commits** format: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`,
  `test:`.
- Subject lines stay short; details go in the body.
- The deterministic pre-commit checks (secret scan, debug-statement scan, large-file warning,
  linter pass) run automatically via `.claude/hooks/pre-commit-check.sh` — no skill
  invocation needed before `git commit`.
- The LLM-judgment portion of the old `/pre-commit` skill (proposing the message itself)
  lives in `/gen-commit-message` — see [40-skills.md](40-skills.md).

## Branch Finishing

- Use `/superpowers:finishing-a-development-branch` to decide what happens at the end of a
  branch: merge, open a PR, keep open, or discard.
- The skill verifies tests pass before any branch-finalizing action — see iron law #4 in
  [10-iron-laws.md](10-iron-laws.md).

## CI Expectations

CI is defined in `.github/workflows/ci.yml`. The gating jobs are:

| Job | Tool / pinned version | Notes |
|---|---|---|
| Validate Shell Scripts | shellcheck `v0.10.0` | Lints `.claude/hooks/*.sh`, `workflows/*.sh`, `scripts/*.sh`. |
| Validate GitHub Actions Workflows | actionlint `1.7.7` | Lints workflow YAML. |
| Validate JSON Files | `jq empty` | Validates `.claude/settings.json`, `mcp/*.json`. |
| Check for Secrets | `grep` | Blocks real-looking `ghp_*` / `sntrys_*` tokens in tracked files. See [60-security-privacy.md](60-security-privacy.md). |
| Verify Project Structure | `test -f` loop | Mirrored in `scripts/verify-ci.sh`. |
| Cross-Platform Smoke | `scripts/validate-skills.sh`, `scripts/test-hooks.sh` | Runs on Ubuntu, macOS, Windows. |

Non-gating jobs (`continue-on-error: true` or `|| true`):

- **Lint Markdown** — informational.
- **Run Example Tests** — `examples/todo-app` ships with three intentional bugs as
  pedagogical fixtures. The run is informational; only `pytest --collect-only` is gating.

Run locally with `bash scripts/verify-ci.sh` for the same checks CI runs, with the same
pinned tool versions. Run `bash scripts/verify.sh` for the broader installation-readiness
check (tools, env, hooks, skills, agents, gh auth).

**Clarification:** the required-files manifest is duplicated between
`.github/workflows/ci.yml` (job `check-structure`) and `scripts/verify-ci.sh`. Any addition
or removal must be mirrored in both — drift causes the inversion "local says red, CI says
green" or vice versa.
