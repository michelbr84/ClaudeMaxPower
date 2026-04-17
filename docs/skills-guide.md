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

ClaudeMaxPower ships two families of skills:

**Pipeline skills** (adapted from [obra/superpowers](https://github.com/obra/superpowers), MIT)
form the brainstorm → spec → plan → execute → finish pipeline. Read each skill file for
full details; the summaries in [superpowers-integration.md](superpowers-integration.md) cover
when to use which one:

- `/brainstorming` — collaborative design refinement, produces an approved spec (hard gate)
- `/writing-plans` — breaks the spec into bite-sized tasks (2-5 min each)
- `/subagent-dev` — dispatches a fresh subagent per task with two-stage review
- `/systematic-debugging` — 4-phase root-cause debugging
- `/using-worktrees` — creates an isolated git worktree with safety checks
- `/finish-branch` — merge / PR / keep / discard + worktree cleanup
- `/tdd-loop` — strict Red-Green-Refactor with iron-law enforcement
- `/tdd-loop-lite` — the simpler TDD loop kept for flexibility

**Native skills** are documented in detail below.

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

### /tdd-loop

Autonomous TDD loop — tests first, implement until green.

```bash
/tdd-loop --spec "Add search_tasks(query) that returns tasks matching query (case-insensitive)" --file src/todo.py
```

**Workflow:** Parse spec → write tests (RED) → write implementation → iterate until GREEN → refactor

**Max iterations:** 10. Reports progress at each iteration.

---

### /pre-commit

Intelligent pre-commit check before every commit.

```bash
/pre-commit
```

**Workflow:** Inspect staged diff → scan for secrets → find debug statements → check large files → run linter → generate commit message

**Output:** Pass/fail report + suggested conventional commit message

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

## Skill vs Agent vs Workflow

| | Skill | Agent | Workflow Script |
|--|-------|-------|----------------|
| **Invoked** | Manually (`/skill`) | By Claude as sub-session | Manually (`bash`) |
| **Memory** | None | Optional (project/user) | None |
| **Multi-file** | Yes | Yes | Yes |
| **Headless** | No | Yes | Yes |
| **Best for** | Interactive workflows | Specialized roles | Batch/CI automation |
