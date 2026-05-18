# 60 — Security and Privacy

Secret handling, destructive-command policy, and the safety boundaries between Claude Code
itself and the ClaudeMaxPower hook backstop.

## Destructive Commands

- **Never run `rm -rf /` or any destructive command without explicit user confirmation.**
  This is one of the Absolute Rules registered in [10-iron-laws.md](10-iron-laws.md).
- The hook `.claude/hooks/pre-tool-use.sh` blocks a regex-matched subset of catastrophic
  patterns (`rm -rf /`, `rm -rf ~`, fork bombs, `dd if=/dev/zero`, `mkfs.`, `DROP TABLE`,
  `DROP DATABASE`, `TRUNCATE TABLE`, force-push to `main`/`master`). It is defense in depth,
  not the primary boundary — see "Hooks vs Claude Code's Sandbox" in
  [`../docs/hooks-guide.md`](../docs/hooks-guide.md).
- The block-list cannot stop obfuscated commands, dangerous behaviour via non-`Bash` tools,
  or logic-level harm. Respect Claude Code's permission prompts; prefer plan mode for risky
  work.

## Secret Handling

- **Never commit `.env` or any file containing real secrets or tokens.** This is one of the
  Absolute Rules registered in [10-iron-laws.md](10-iron-laws.md).
- The hook `.claude/hooks/pre-commit-check.sh` inspects `git diff --staged` for likely
  secrets (api keys, tokens, passwords) and blocks the commit if any are found — see
  [`../docs/hooks-guide.md`](../docs/hooks-guide.md).
- The CI job `validate-no-secrets` blocks pushed commits that contain real-looking GitHub
  (`ghp_*`) or Sentry (`sntrys_*`) tokens anywhere in tracked files, including `.env.example`.
  See [30-git-github-ci.md](30-git-github-ci.md).
- `.env` is local-only. If it does not exist, the session-start hook warns the user and
  suggests `bash scripts/setup.sh`.

## Audit Logging

- Every bash command Claude runs is logged to `.claude/audit.log` by
  `.claude/hooks/pre-tool-use.sh` with a timestamp.
- `.claude/audit.log` is in `.gitignore` — it is local only and never pushed.

## Test Isolation

The rule "never mock the filesystem or database in tests when real implementations are
available" lives in [10-iron-laws.md](10-iron-laws.md) under "Test Discipline". It belongs
there because a violation also violates the TDD iron law's "for the right reason" clause.
