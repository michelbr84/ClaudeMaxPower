# 10 — Iron Laws

Non-negotiable rules. The Four Iron Laws are the foundation of the unified pipeline; the
"Absolute Rules" register below cross-references the other policies that are equally
non-negotiable but live in topic-specific files.

## The Four Iron Laws

These are enforced by the skills and hooks documented in [20-workflow.md](20-workflow.md) and
[40-skills.md](40-skills.md) and must be respected in every session.

1. **No production code without a failing test first** — enforced by
   `/superpowers:test-driven-development`. A test must be written, observed to fail for the
   right reason, and only then is implementation code allowed. The "for the right reason"
   clause matters: a test that fails because of a typo is not a red test.
2. **No implementation without an approved spec** — enforced by the
   `/superpowers:brainstorming` hard gate. Non-trivial work requires a spec that names the
   problem, the chosen approach, and the success criteria. Trivial work (one-line fixes,
   typos) is exempt.
3. **No fixes without root cause investigation** — enforced by
   `/superpowers:systematic-debugging` Phase 1. Symptoms are not causes. A fix that makes
   the symptom go away without explaining why the symptom appeared is provisional at best.
4. **No merging with failing tests** — enforced by
   `/superpowers:finishing-a-development-branch` Step 1 (verify). The test suite runs green
   before merge, PR, or any branch-finalizing action.

The laws are cumulative. A change that passes tests (law 4) but skipped the spec (law 2) is
still a violation. A change with a spec and passing tests but no root-cause analysis (law 3)
is still a violation when it touches bug territory.

### Narrow Exceptions

Each law has a narrow exception that exists so the methodology does not become theater. Using
an exception routinely is a signal that the shape of the work has shifted and the pipeline
should be reconsidered.

- **Law 1 exception** — Exploratory spikes that will be deleted before merging. Use a scratch
  branch with informal testing. The moment the spike becomes real code, the law applies
  retroactively — tests come before further production code.
- **Law 2 exception** — Trivial changes (typos, obvious one-liners, formatting) do not need a
  spec. A change is "trivial" when a reviewer would not ask "why?" about it.
- **Law 3 exception** — Known flakes with documented workarounds can be patched without deep
  root-cause investigation if the patch itself is well-isolated. The underlying cause stays
  on the backlog.
- **Law 4 exception** — None. Failing tests block the merge. If a test is known-broken and
  unrelated, it must be marked as skipped with a tracking issue, not ignored.

## Absolute Rules Register

These are the project-wide "never do" rules. Each is owned by a topic-specific file; this
register exists so a reader who only opens one rule file still sees the complete inventory.

| Rule | Owning file |
|------|-------------|
| Never run `rm -rf /` or any destructive command without explicit user confirmation. | [60-security-privacy.md](60-security-privacy.md) |
| Never commit `.env` or any file containing real secrets or tokens. | [60-security-privacy.md](60-security-privacy.md) |
| Never push to `main` or `master` directly. Always use a feature branch + PR. | [30-git-github-ci.md](30-git-github-ci.md) |
| Never skip tests when they exist. If tests fail, fix the code, not the tests. | This file — see "Test Discipline" below |
| Never mock the filesystem or database in tests when real implementations are available. | This file — see "Test Discipline" below |

## Test Discipline

The two test-related "never" rules live here because they belong with the TDD iron law:

- **Never skip tests when they exist.** If tests fail, fix the code, not the tests. Marking a
  test skipped is permitted only under Law 4's narrow exception (known-broken, unrelated, with
  a tracking issue).
- **Never mock the filesystem or database in tests when real implementations are available.**
  Tests that mock components that could be real are a smell — they pass even when the real
  contract is broken. Use temporary directories for filesystem tests and a real (test-scoped)
  database when one is available.

## Verifying Subagent Reviews

`/superpowers:subagent-driven-development` and `Agent(subagent_type=code-reviewer)` produce
structured review output that looks authoritative. Treat reviewer output as a high-signal
*hypothesis*, not a verdict. Verify each claim against the code before applying it.

This is an iron-law variant of Law 3 (no fixes without root-cause investigation) applied to
the case where the "report" comes from another LLM session rather than a human bug report.

- **Read the cited line.** A claim like "off-by-one in the truncation loop" only matters if
  the loop actually has the off-by-one. Open the file at the cited line and decide for
  yourself.
- **Reproduce the alleged failure with a test.** If the reviewer says behaviour X is wrong for
  input Y, write the test that asserts the correct behaviour. If the test passes, the claim
  was wrong; if it fails, the fix is grounded.
- **Distinguish style notes from correctness claims.** Style and naming critiques are usually
  safe to apply on judgment alone. Correctness, performance, and security claims need
  empirical confirmation.
- **Resist the "it's-the-reviewer-so-it-must-be-right" reflex.** The whole point of two-stage
  review is to surface signal — not to bypass your own judgment.
