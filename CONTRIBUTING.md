# Contributing to ClaudeMaxPower

Thanks for your interest in contributing. ClaudeMaxPower is an opinionated template that
turns Claude Code into a coordinated AI engineering team. Contributions that strengthen
the methodology, harden the hooks, broaden cross-platform support, or improve the docs
are very welcome.

This guide tells you how to propose changes and what we expect from a PR. The full
methodology lives in [`CLAUDE.md`](CLAUDE.md) and
[`docs/superpowers-integration.md`](docs/superpowers-integration.md); please skim those
before opening a non-trivial PR.

## Ways to contribute

- **Report a bug** — open a GitHub issue using the `bug_report` template.
- **Propose a feature or new skill** — open an issue using the `feature_request` template
  and, ideally, run `/superpowers:brainstorming` to produce a spec before writing code
  (install the Superpowers plugin with `/plugin install superpowers@claude-plugins-official`
  if you haven't already).
- **Improve docs** — small fixes (typos, broken links, clarifications) are welcome as
  direct PRs. Larger structural changes deserve an issue first.
- **Report a security issue** — do **not** use public issues. See [`SECURITY.md`](SECURITY.md).

## Setting up your environment

```bash
git clone https://github.com/michelbr84/ClaudeMaxPower
cd ClaudeMaxPower
bash scripts/setup.sh
cp .env.example .env   # then fill in tokens
```

You need:

- `bash` (Git Bash on Windows)
- `git` 2.30+
- `gh` CLI (for skills that talk to GitHub)
- Python 3.11+ (for the `examples/todo-app` test suite)
- `jq` (used by setup and several workflow scripts)

`bash scripts/test-hooks.sh` self-tests every hook script in an isolated tmp workspace
and is the fastest way to verify your environment is correctly wired before you open a PR.

## The pipeline we expect for non-trivial changes

ClaudeMaxPower is built around a deliberate pipeline. Please follow it for anything that
isn't a one-line fix:

The pipeline lives upstream in the Superpowers plugin (install once with
`/plugin install superpowers@claude-plugins-official`):

```
/superpowers:brainstorming                      → docs/specs/YYYY-MM-DD-<topic>-design.md   (hard gate: spec must be approved)
/superpowers:writing-plans                      → docs/plans/YYYY-MM-DD-<topic>-plan.md     (bite-sized tasks)
/superpowers:using-git-worktrees                → isolated branch workspace
/superpowers:subagent-driven-development        → fresh subagent per task + two-stage review
/superpowers:finishing-a-development-branch     → merge / PR / keep / discard
```

If you type one of the legacy unqualified names (`/brainstorming`, `/writing-plans`, …)
the `/superpowers-redirect` skill catches it and points you at the canonical command.

Trivial changes (typos, obvious one-liners, formatting) are exempt from the spec gate. A
change is "trivial" when a reviewer would not ask "why?" about it.

## The four iron laws

These apply to every PR:

1. **No production code without a failing test first.** Run
   `/superpowers:test-driven-development` for any new behavior — write the test, watch it
   fail, write the minimal code to pass. (Install the Superpowers plugin with
   `/plugin install superpowers@claude-plugins-official` if you haven't already.)
2. **No implementation without an approved spec.** Use `/superpowers:brainstorming` for
   non-trivial work and link the spec from your PR.
3. **No fixes without root-cause investigation.** Use `/superpowers:systematic-debugging`
   for any bug whose cause isn't immediately obvious. A patch that makes the symptom
   disappear without explaining why the symptom appeared is provisional at best.
4. **No merging with failing tests.** CI must be green before merge.

## Coding conventions

- **Languages.** Match the language of the file you are modifying. Most of the repo is
  shell, Markdown, and Python.
- **Shell scripts.** `set -euo pipefail`, quote every variable, use `local` inside
  functions. The `Validate Shell Scripts` CI job runs `shellcheck` on every script under
  `.claude/hooks/`, `workflows/`, and `scripts/`.
- **Python.** PEP 8, type hints on public functions, `pytest` for tests. The `Run Example
  Tests` CI job exercises `examples/todo-app/`.
- **Markdown.** ATX headings (`#`), 100-char line limit, fenced code blocks with language
  tags. Lint with `markdownlint` if you have it installed locally.
- **Workflows.** Each workflow needs an explicit `permissions:` block at minimum scope.
  Pin third-party actions by full commit SHA; first-party `actions/*` may be tag-pinned.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>

<body explaining the why, not the what>

<footer with breaking-change or co-author markers>
```

Types we use frequently:

- `feat:` new user-visible feature
- `fix:` bug fix
- `docs:` documentation only
- `chore:` tooling, config, hygiene
- `ci:` CI / workflow changes
- `refactor:` no behavior change
- `test:` test-only

When you collaborate with Claude Code, append the co-author trailer:

```
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Never use `--no-verify` to bypass hooks. If a hook fails, fix the underlying issue and
create a *new* commit.

## Pull requests

Before opening a PR:

- Branch off the latest `main` (`git fetch origin && git rebase origin/main` — only on
  branches you have not pushed yet, or use a merge if you have).
- The `.claude/hooks/pre-commit-check.sh` hook runs automatically before every `git commit`
  — it scans staged changes for secrets (blocking), debug statements, large files, and
  linter issues (all warnings). No manual invocation needed; just run `git commit`.
- Run any tests that touch your changes (`pytest examples/todo-app/tests/`,
  `bash scripts/test-hooks.sh`, `bash scripts/validate-skills.sh`).
- Make sure `git status` is clean and you are committing only the intended files.

Open the PR with:

- A descriptive title that begins with a Conventional Commits type.
- A summary of *what* changed and *why*.
- A test plan (what you ran, what you observed).
- Links to the spec, the plan, and any related issue or PR.

The PR template will prompt for these. Required CI checks must be green before merge.

## Reviewing other PRs

If you review a PR, treat the diff with technical rigor. Do not approve performatively.
Verify each correctness or security claim against the actual code — see the section
on "Verifying subagent reviews" in
[`docs/superpowers-integration.md`](docs/superpowers-integration.md).

## What not to do

- Do **not** push directly to `main`. Branch protection enforces a PR + green CI.
- Do **not** commit `.env` or any file containing real tokens. The
  `Check for Secrets` CI job greps for known token shapes; secret scanning push
  protection is also enabled at the repo level.
- Do **not** `git push --force` or rewrite published history.
- Do **not** weaken branch protection, required checks, or any security setting in a PR.
  Those changes belong in a separate, approval-gated discussion.
- Do **not** remove the attribution block from skills adapted from
  [obra/superpowers](https://github.com/obra/superpowers). See
  [`ATTRIBUTION.md`](ATTRIBUTION.md).

## Code of conduct

Be kind. Assume good faith. Critique the code, not the person. Maintainers reserve the
right to close PRs and issues that are abusive, off-topic, or not aligned with the
project's stated goals.

## License

By contributing, you agree that your contributions will be licensed under the project's
MIT License (see [`LICENSE`](LICENSE)). If you adapt code from another MIT-licensed
project, add the upstream attribution to [`ATTRIBUTION.md`](ATTRIBUTION.md) following the
existing format.
