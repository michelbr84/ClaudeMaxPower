# Skills Guide

Skills are reusable AI workflows defined in markdown files. They act like "engineering macros" — you invoke them once, they execute a complete multi-step workflow.

## How Skills Work

A skill is a `.md` file in the `skills/` directory with:
- **YAML frontmatter** — metadata: name, description, arguments, allowed tools
- **Markdown body** — step-by-step instructions Claude follows

Invoke a skill inside Claude Code:
```
/fix-issue --issue 42 --repo owner/repo
```

Claude reads the skill file, substitutes your arguments, and executes the workflow.

## Skill Frontmatter

```yaml
---
name: skill-name
description: What this skill does
arguments:
  - name: issue
    description: GitHub issue number
    required: true
  - name: repo
    description: Repository (owner/repo)
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Glob
  - Grep
---
```

The `allowed-tools` list restricts which Claude tools the skill can use — a security boundary.

## Available Skills

The methodology skills (brainstorming, plans, TDD, debugging, worktrees, finish) live
upstream in the **Superpowers plugin**. Install with
`/plugin install superpowers@claude-plugins-official` and invoke them under the
`/superpowers:*` namespace. Read [superpowers-integration.md](superpowers-integration.md)
for when to use each one.

ClaudeMaxPower keeps one stub — `/superpowers-redirect` — that catches the old slash
commands (`/brainstorming`, `/tdd-loop`, etc.) and points users to the canonical
replacements.

**Native ClaudeMaxPower skills** are documented in detail below.

### /max-power

One-command activation. Detects environment, runs setup, offers Superpowers plugin install,
presents the pipeline menu, and routes you to the right entry point for your goal.

```bash
/max-power
/max-power --goal "fix the login bug"
/max-power --mode new-project
```

**Workflow:** Detect env → Install ClaudeMaxPower if missing → Offer Superpowers plugin → Run setup → Read project context → Route to skill

---

### /fix-issue

Fix a GitHub issue end-to-end using TDD.

```bash
/fix-issue --issue 42 --repo owner/repo
```

**Workflow:** Read issue → find affected code → write failing test → fix bug → run tests → open PR

**Requires:** `GITHUB_TOKEN` in `.env`, `gh` CLI authenticated

---

### /review-pr

Full structured PR review posted as a GitHub comment.

```bash
/review-pr --pr 55 --repo owner/repo
```

**Workflow:** Fetch diff → analyze correctness/security/tests/style → post structured review → label verdict

**Output:** Review comment on the PR with APPROVED / CHANGES REQUESTED / NEEDS DISCUSSION

---

### /refactor-module

Safe module refactor with test-backed confidence.

```bash
/refactor-module --file src/auth.py --goal "extract token validation into validate_token()"
```

**Workflow:** Read file → read tests → capture baseline → refactor → run tests → report

**Stops if:** Tests don't exist (unsafe to refactor) or tests are already failing before refactor

---

### /gen-commit-message

Read the staged diff and propose a Conventional Commits message. Replaces the LLM portion
of the old `/pre-commit` skill — the deterministic checks (secrets, debug statements, large
files, linter) now run automatically via the `pre-commit-check.sh` hook.

```bash
/gen-commit-message
```

**Workflow:** Verify staged changes → read diff → propose `<type>(<scope>): <subject>` → ask user "use / edit / regenerate"

---

### /superpowers-redirect

Catches the old slash commands that have moved upstream (`/brainstorming`,
`/writing-plans`, `/subagent-dev`, `/tdd-loop`, `/systematic-debugging`,
`/using-worktrees`, `/finish-branch`) and tells the user the canonical `/superpowers:*`
replacement.

---

### /generate-docs

Auto-generate API documentation from source code.

```bash
/generate-docs --dir src/
```

**Workflow:** Find source files → extract public functions/classes → add missing docstrings → write `docs/api/*.md` → update index

---

## Writing Your Own Skills

Create a new file in `skills/`:

```markdown
---
name: deploy-staging
description: Deploy the current branch to the staging environment
arguments:
  - name: branch
    description: Branch to deploy (default: current branch)
    required: false
allowed-tools:
  - Bash
---

# Skill: deploy-staging

## Workflow

### Step 1: Get current branch
\```bash
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
\```

### Step 2: Run pre-deploy checks
...

### Step 3: Deploy
...
```

**Tips for writing skills:**
- Use numbered steps — makes it easy to resume if something fails
- Include the bash commands literally — Claude runs them
- Specify what to do on failure, not just on success
- Keep `allowed-tools` minimal — principle of least privilege
- Test the skill end-to-end before sharing

## Progressive Disclosure: skills/references/

Heavy reference content — long checklists, role catalogues, install scripts, helper one-liners — lives under `skills/references/` instead of being inlined into the skill body.
The skill points to the reference file when it needs the content; Claude reads it on demand
rather than on every session start.

Current reference files:

| File | Used by |
|---|---|
| `skills/references/team-roster.md` | `/assemble-team` Step 3 (role catalogue, composition rules, spawn order, dependencies) |
| `skills/references/review-pr-checklist.md` | `/review-pr` Step 3 (Correctness/Security/Tests/Style/Breaking/Operational checklist) |
| `skills/references/max-power-install-strategies.md` | `/max-power` Step 2 (in-place / subdirectory / tarball-fallback install commands) |
| `skills/references/max-power-status-dashboard.md` | `/max-power` Step 7 (status block template) |
| `skills/references/extract-api-python.sh` | `/generate-docs` Step 1 (Python API surface extraction) |
| `skills/references/extract-api-typescript.sh` | `/generate-docs` Step 1 (TypeScript/JavaScript API surface extraction) |

When you write a new skill: if the body grows past ~150 lines or contains a long table /
checklist / template that would be useful to other skills, extract it to
`skills/references/<topic>.md` and reference it from the skill body.

## Validate Skill Frontmatter

Run `bash scripts/validate-skills.sh` after editing or adding a skill to confirm
the YAML frontmatter has the required fields and that every entry in
`allowed-tools` is a recognised Claude Code tool. By default unknown tools are
warnings; `--strict` (or `CMP_STRICT_TOOLS=1`) escalates them to failures.

The known-tool list lives in `scripts/known-claude-tools.txt` — append to it when
Claude Code introduces a new tool you want to use.

## Skill vs Agent vs Workflow

| | Skill | Agent | Workflow Script |
|--|-------|-------|----------------|
| **Invoked** | Manually (`/skill`) | By Claude as sub-session | Manually (`bash`) |
| **Memory** | None | Optional (project/user) | None |
| **Multi-file** | Yes | Yes | Yes |
| **Headless** | No | Yes | Yes |
| **Best for** | Interactive workflows | Specialized roles | Batch/CI automation |
