---
name: max-power
description: One-command activation — installs ClaudeMaxPower, offers Superpowers plugin install, presents capabilities menu, and routes the user to the right skill for their immediate goal.
arguments:
  - name: goal
    description: What you want to accomplish right now (free text; the skill picks the best entry point)
    required: false
  - name: mode
    description: "new-project | existing-project | auto (default: auto)"
    required: false
  - name: install-superpowers-plugin
    description: "yes | no | ask (default: ask)"
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
  - TaskCreate
  - TaskUpdate
---

# Skill: max-power

One-command activation for the full ClaudeMaxPower stack. Detects the environment, installs
what's missing, offers the optional Superpowers plugin, wires up the skills pipeline, and
routes the user to the right entry point for their immediate goal.

This is the intended first command in any new shell. If `/max-power` runs cleanly, the full
engineering pipeline (brainstorming -> plan -> subagent-driven dev -> review -> finish) is
live and every governance hook is active.

## Announce

Print exactly:

```
Activating ClaudeMaxPower at maximum capability.
```

Then proceed through the steps below. Do not skip steps. If any step fails, report the
failure clearly and continue with the next step where possible.

## Step 1 — Detect environment

Run each check and record the result. Prefer non-interactive shell commands.

### 1.1 Git repository?

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Record `IS_GIT=yes|no`. If no, warn the user — many skills (worktrees, finish-branch,
pre-commit, fix-issue, review-pr) require git.

### 1.2 ClaudeMaxPower already installed?

ClaudeMaxPower is considered installed when all three markers are present:

- `.claude/hooks/session-start.sh` exists
- `skills/assemble-team.md` exists
- `CLAUDE.md` exists and contains the string `ClaudeMaxPower`

Record `CMP_INSTALLED=yes|no`.

### 1.3 New or existing project?

Count source files that are not part of ClaudeMaxPower:

```bash
# Rough heuristic — count files outside .claude, skills, docs, scripts, workflows
find . -type f \
  -not -path './.git/*' \
  -not -path './.claude/*' \
  -not -path './skills/*' \
  -not -path './docs/*' \
  -not -path './scripts/*' \
  -not -path './workflows/*' \
  -not -path './node_modules/*' \
  -not -path './.venv/*' \
  | wc -l
```

If fewer than 10 non-CMP files AND no `README.md` (or only the CMP one) AND no source tree
(`src/`, `app/`, `lib/`, package.json, pyproject.toml, go.mod, Cargo.toml): `PROJECT_KIND=new`.
Otherwise: `PROJECT_KIND=existing`.

The `mode` argument overrides detection. If `mode=new-project` or `mode=existing-project`,
use that value. Otherwise use the detection result.

### 1.4 Detect tech stack

Probe for each and record which exist:

- `package.json` -> Node/JS/TS
- `requirements.txt`, `pyproject.toml`, `Pipfile` -> Python
- `go.mod` -> Go
- `Cargo.toml` -> Rust
- `pom.xml`, `build.gradle` -> Java/JVM
- `Gemfile` -> Ruby

Record `TECH_STACK` as a comma-separated list. Used later to tailor pre-commit checks and
test runners.

## Step 2 — Install ClaudeMaxPower (only if not present)

Skip this step entirely if `CMP_INSTALLED=yes`.

### 2.1 Decide install strategy

If current directory is empty: install in-place.

If current directory has files and CMP is not installed: ask the user:

```
ClaudeMaxPower is not installed in this directory and the directory is not empty.
Choose an install strategy:
  1) In-place — merge ClaudeMaxPower files alongside existing code (safe: will not overwrite)
  2) Subdirectory — clone into ./claudemaxpower/ and ask you to cd into it
  3) Abort — do nothing
```

Wait for user choice before proceeding.

### 2.2 Clone and merge

For in-place install, use `rsync` with `--ignore-existing` so user files are never
overwritten:

```bash
TMP="/tmp/cmp-$$"
git clone --depth 1 https://github.com/michelbr84/ClaudeMaxPower "$TMP"
rsync -a --ignore-existing --exclude='.git' "$TMP/" ./
rm -rf "$TMP"
```

For subdirectory install:

```bash
git clone --depth 1 https://github.com/michelbr84/ClaudeMaxPower ./claudemaxpower
echo "Installed into ./claudemaxpower. cd into it and re-run /max-power."
```

### 2.3 Fallback if clone fails

If `git clone` fails (no network, no git, proxy issues):

```bash
curl -fsSL https://github.com/michelbr84/ClaudeMaxPower/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=1 -C .
```

If both fail, report the error and stop. Ask the user to download the repo manually.

## Step 3 — Offer the Superpowers plugin (optional)

Tell the user:

```
ClaudeMaxPower already inlines the core Superpowers methodology — brainstorming,
writing-plans, subagent-dev, tdd-loop, systematic-debugging, using-worktrees, and
finish-branch are all available right now.

The official Superpowers plugin adds extra skills (frontend-design, mcp-builder,
writing-clearly-and-concisely, elements-of-style, and more). It is optional.
```

Decision logic:

- If `install-superpowers-plugin=yes`: tell the user to run the slash command themselves
  (this skill cannot execute slash commands). Provide exact copy-paste text:

  ```
  /plugin install superpowers@claude-plugins-official
  ```

- If `install-superpowers-plugin=no`: skip silently.
- If `ask` or unset: prompt the user with a one-line question. Default to no.

## Step 4 — Run setup script

Run the project bootstrap if it exists:

```bash
if [ -f scripts/setup.sh ]; then
  bash scripts/setup.sh
fi
```

Capture missing-tool warnings from setup output and surface them:

- `gh` not installed -> `/fix-issue` and `/review-pr` cannot talk to GitHub
- `jq` not installed -> batch workflows degrade gracefully
- `graphviz` not installed -> `workflows/dependency-graph.sh` needs it
- `.env` placeholders still unfilled -> warn

Do not fail hard on missing tools. Warn and continue.

## Step 5 — Activate skills pipeline

Load project context so downstream skills have everything they need.

- Read `CLAUDE.md` if present. Note project identity, conventions, absolute rules.
- Read `README.md` if present. Note goals and usage.
- Read manifests for installed tech stacks: `package.json`, `pyproject.toml`,
  `requirements.txt`, `go.mod`, `Cargo.toml`.
- Run `git status --short` and `git log --oneline -n 10` to understand active work.
- If `.estado.md` exists, read it — the session-start hook writes session summaries there.

Keep the summary in working memory for Step 7 status dashboard. Do not print raw file
contents unless the user asks.

## Step 6 — Route to the immediate goal

### 6.1 If a `goal` argument was provided, classify it

Match against these intent keywords (case-insensitive, any match counts):

| Keywords | Route |
|---------|------|
| `bug`, `fix`, `error`, `broken`, `crash`, `regression` | `/systematic-debugging` (or `/fix-issue` if a GitHub issue number is mentioned) |
| `new feature`, `add`, `build`, `create`, `implement` | `/brainstorming` (hard gate) |
| `review`, `pr`, `pull request` | `/review-pr` |
| `refactor`, `rename`, `extract`, `cleanup` | `/refactor-module` |
| `test`, `tdd`, `coverage` | `/tdd-loop` |
| `docs`, `readme`, `documentation` | `/generate-docs` |
| `team`, `parallel`, `several tasks` | `/assemble-team` |
| `commit`, `stage`, `ready to push` | `/pre-commit` |

When you route, do not execute the downstream skill yourself. Tell the user the exact
command to run and a one-line rationale. Example:

```
Route: /brainstorming user-auth
Why: you asked to "add authentication" — we brainstorm the spec first (hard gate) before
any code is written.
```

### 6.2 If no goal was provided, show the menu

Print this menu verbatim:

```
Claude Code + ClaudeMaxPower is active at maximum capability.

Recommended pipeline:
  1) /brainstorming <topic>        Design the feature (spec gate)
  2) /writing-plans <spec-file>    Break spec into tasks
  3) /subagent-dev <plan-file>     Execute via fresh subagents + 2-stage review
  4) /finish-branch                Merge / PR / cleanup

Alternate entry points:
  /assemble-team --mode new-project --description "..."
  /fix-issue --issue <N> --repo owner/repo
  /systematic-debugging --issue "<describe bug>"
  /tdd-loop --spec "..." --file path
  /review-pr --pr <N> --repo owner/repo
  /refactor-module --file <path> --goal "..."
  /pre-commit
  /generate-docs --dir src/

Governance skills (auto-fire):
  - session-start hook   context restore + Auto Dream
  - pre-tool-use hook    blocks dangerous commands
  - post-tool-use hook   auto-run tests on edit
  - stop hook            persist .estado.md

What's your goal? (free text or pick a number above)
```

## Step 7 — Status dashboard

End with a compact, emoji-free status block. Fill values from what was detected and
installed:

```
ClaudeMaxPower status
---------------------
Version            v2.0
Mode               new-project | existing-project
Tech stack         <detected list or "none detected">
Skills loaded      brainstorming, writing-plans, subagent-dev, tdd-loop, tdd-loop-lite,
                   systematic-debugging, finish-branch, using-worktrees, assemble-team,
                   fix-issue, review-pr, refactor-module, pre-commit, generate-docs
Hooks active       session-start, pre-tool-use, post-tool-use, stop
Agent teams        enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
Auto Dream         configured (trigger: 24h + 5 sessions)
Superpowers plugin <installed | not installed>
Environment        <.env ok | .env missing placeholders>
Next action        <recommended skill from Step 6>
```

## Error handling summary

- `git clone` fails -> try tarball fallback (`curl | tar -xz`). If both fail, stop and ask
  the user to download manually.
- `rsync` not available -> fall back to `cp -n -R` (no-clobber).
- `setup.sh` missing a tool -> warn, continue, note it in the status dashboard under
  Environment.
- Project files already exist and strategy is in-place -> always use `--ignore-existing` /
  `-n` so user files are never overwritten. If a collision would happen, list the colliding
  paths and skip them.
- User declines install in Step 2 -> stop cleanly. Do not leave partial state.
- `goal` argument is ambiguous (matches multiple intents) -> ask once for clarification,
  then route.

## Cross-references

- Hooks: [`docs/hooks-guide.md`](../docs/hooks-guide.md)
- Skills: [`docs/skills-guide.md`](../docs/skills-guide.md)
- Agents: [`docs/agents-guide.md`](../docs/agents-guide.md)
- Agent teams: [`docs/agent-teams-guide.md`](../docs/agent-teams-guide.md)
- Auto Dream: [`docs/auto-dream-guide.md`](../docs/auto-dream-guide.md)
- Batch workflows: [`docs/batch-workflows.md`](../docs/batch-workflows.md)
- Copy-paste bootstrap prompt: [`docs/bootstrap-prompt.md`](../docs/bootstrap-prompt.md)

## Success criteria

`/max-power` has succeeded when all of the following are true:

- ClaudeMaxPower files are present (hooks, skills, scripts)
- `.claude/settings.json` has `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (agent teams live)
- The session-start hook has run at least once this session (context restored)
- The user has a clear next action — either a routed skill invocation or the menu
- The status dashboard was printed

If any criterion fails, report which one and what to do about it.
