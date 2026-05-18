# 90 — Maintenance and Rule Hygiene

How to add a new rule, retire an old one, and keep this directory consistent over time.

## Adding a New Rule

1. Decide which existing file owns the topic. The file table in
   [00-index.md](00-index.md) is the index of scopes.
2. Add the rule to the most specific file. If the rule is also non-negotiable
   project-wide, add a one-line entry to the "Absolute Rules Register" in
   [10-iron-laws.md](10-iron-laws.md) pointing at the owning file — do not repeat the rule
   text there.
3. If the rule needs a new scope that no existing file covers, create a new numbered file
   (gaps in the numbering are fine) and add it to the table in [00-index.md](00-index.md).

## Retiring a Rule

- A rule is "retired" by removing it from its owning file and from any cross-reference in
  [10-iron-laws.md](10-iron-laws.md) or [00-index.md](00-index.md).
- Do not leave stub references behind. Either the rule applies or it does not.
- If a rule was once enforced by a hook, skill, or CI check that has been removed, retire the
  rule together with the enforcement mechanism — otherwise readers will assume the
  enforcement still exists.

## Avoiding Duplication

- A rule is stated once. Broader files reference the specific file instead of repeating the
  rule.
- The "Absolute Rules Register" in [10-iron-laws.md](10-iron-laws.md) is the one explicit
  exception: it lists each project-wide non-negotiable as a single-line pointer, so the
  reader of any one file still gets the full inventory.

## Resolving Apparent Contradictions

If two files appear to contradict each other:

1. The more specific file wins by default.
2. Open an issue or fix the inconsistency in the same PR that introduced it.
3. If the contradiction is between an iron law and a topic rule, the iron law wins — that is
   the whole point of [10-iron-laws.md](10-iron-laws.md).

## Validating This Directory

The repository's existing validation scripts cover the surrounding infrastructure but do not
validate rule content. The supported validation today is:

- `bash scripts/verify.sh` — installation-readiness check.
- `bash scripts/verify-ci.sh` — locally mirrors the CI gating jobs.
- `bash scripts/validate-skills.sh` — skill frontmatter validation.
- `bash scripts/test-hooks.sh` — hook self-tests.

When editing rule files, manually:

1. Confirm the link to [00-index.md](00-index.md) from [`../CLAUDE.md`](../CLAUDE.md) still
   resolves.
2. Confirm every relative link in this directory still resolves.
3. Confirm no rule appears in two files (search the directory with `Grep` for distinctive
   phrasing).

## When CLAUDE.md and rules/ Disagree

[`../CLAUDE.md`](../CLAUDE.md) is the entrypoint and should remain useful on its own, but it
no longer carries the full rule corpus. When the entrypoint and a rule file disagree:

- The rule file wins (more specific).
- The entrypoint should be updated to summarize the rule file correctly.
- A discrepancy of this kind is a small bug — fix it the next time you touch either file.
