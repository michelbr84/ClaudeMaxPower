# Bootstrap Prompt

A single copy-paste prompt that activates the full ClaudeMaxPower + Superpowers methodology
from any AI coding assistant — Claude Code, Cursor, Codex CLI, Gemini CLI, or any other
shell-capable coding agent. Paste it into a fresh session and the assistant will install
the stack, wire up governance hooks, and present the recommended engineering pipeline.

## Part A — The copy-paste prompt

Paste everything inside the fence verbatim into your coding assistant as the first message
of a new session. Do not edit the text — the assistant needs the full instructions to know
what to do.

```text
You are now operating under the ClaudeMaxPower + Superpowers methodology.

ClaudeMaxPower (https://github.com/michelbr84/ClaudeMaxPower) is an open-source template
that turns a coding assistant into a coordinated AI engineering team: brainstorming-gated
design, spec-to-plan conversion, subagent-driven development with strict TDD, systematic
debugging, worktree isolation, and governance hooks. It integrates the core obra/superpowers
methodology so every feature is designed before it is built, every line of code is tested,
and every bug is traced to its root cause before a fix is proposed.

Your first task is to bootstrap this system in the current directory. Do the following in
order and report progress as you go:

1. Check whether a skill or slash command named "max-power" is already available in this
   session. If yes, invoke it now (`/max-power`) and stop this checklist — max-power
   handles everything else. If no, continue.

2. Detect the environment:
   - Is this a git repository? (`git rev-parse --is-inside-work-tree`)
   - Does the directory already contain ClaudeMaxPower? Markers: `.claude/hooks/session-start.sh`,
     `skills/assemble-team.md`, and `CLAUDE.md` containing the string "ClaudeMaxPower".
   - Is this a new or existing project? If fewer than 10 non-ClaudeMaxPower source files
     and no real README, treat it as new. Otherwise existing.

3. If ClaudeMaxPower is NOT installed, install it. Prefer in-place merge that never
   overwrites the user's files:
       TMP="/tmp/cmp-$$"
       git clone --depth 1 https://github.com/michelbr84/ClaudeMaxPower "$TMP"
       rsync -a --ignore-existing --exclude='.git' "$TMP/" ./
       rm -rf "$TMP"
   If `git clone` fails, fall back to:
       curl -fsSL https://github.com/michelbr84/ClaudeMaxPower/archive/refs/heads/main.tar.gz \
         | tar -xz --strip-components=1 -C .
   If the directory is non-empty and a collision would overwrite user code, stop and ask
   the user how to proceed (in-place, subdirectory, or abort).

4. If you are running inside Claude Code, offer to install the official Superpowers plugin
   for extra skills (frontend-design, mcp-builder, writing-clearly-and-concisely, and more).
   You cannot run slash commands yourself — instead, tell the user to paste this command:
       /plugin install superpowers@claude-plugins-official
   If the user declines or you are not running in Claude Code, skip this step.

5. Run `bash scripts/setup.sh`. Report any missing tools (`gh`, `jq`, `graphviz`) and any
   `.env` placeholders that still need values.

6. Read `CLAUDE.md` (and `README.md` if present) so you understand the project's conventions
   and absolute rules. Also read `.estado.md` if it exists to restore any previous session
   context.

7. Present the recommended pipeline to the user and WAIT for them to choose a goal. Do not
   start modifying code. The menu:

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

From this point forward, operate under these non-negotiable rules:

- Brainstorm before building. No feature is implemented without an approved spec produced
  by the brainstorming skill. This is a hard gate, not a suggestion.
- Strict TDD is the iron law. Every new behavior starts with a failing test. Never write
  implementation code before there is a red test that describes it.
- Never fix a bug without root cause investigation. Use the systematic-debugging skill's
  four phases (reproduce, isolate, understand, fix) before proposing any change.
- Prefer subagent-driven development for multi-task plans. Spawn a fresh subagent per task,
  run a two-stage review (implementer + reviewer), and merge results via the coordinator.
- Respect governance hooks. The pre-tool-use hook blocks dangerous commands; the
  post-tool-use hook auto-runs tests after edits; the session-start hook restores context
  and may trigger Auto Dream memory consolidation. Do not bypass them.
- Never commit `.env` or real secrets. Never push directly to main. Always use a feature
  branch and a PR via the finish-branch skill.

Reply with: Ready to brainstorm your first feature — what's the goal?
```

## Part B — Variants and notes

### Short version (already-installed)

If ClaudeMaxPower is already installed and you just want to flip the session into maximum
mode, paste this instead:

```text
Invoke /max-power. If the skill is not available, read CLAUDE.md and skills/max-power.md,
then execute the skill's workflow verbatim: detect environment, run bash scripts/setup.sh,
load project context, and present the pipeline menu. Operate under strict TDD, systematic
debugging, and the brainstorm-before-code hard gate from this point forward. Reply with:
Ready to brainstorm your first feature — what's the goal?
```

### Platform notes

Claude Code is the primary target and supports every capability described above. Adjust for
other platforms as follows:

- **Cursor** — Drop the `/plugin install superpowers@claude-plugins-official` step (Cursor
  does not support Claude Code plugins). The inlined ClaudeMaxPower skills still work
  because they are plain markdown that the assistant reads from `skills/`. The governance
  hooks only fire under Claude Code; in Cursor they are informational. Invoke a skill by
  asking the assistant to "follow the instructions in `skills/<name>.md`".
- **Codex CLI / OpenAI CLI** — Same as Cursor: no plugin install, no Claude-specific hooks.
  Skills are read from disk. Agent teams (parallel subagents) may not be supported; fall
  back to sequential skill execution.
- **Gemini CLI** — Same treatment. You may need to tell the assistant to use its shell tool
  explicitly for the `git clone` and `rsync` steps.
- **Generic prompt in any chat UI** — Skip the install step entirely; copy-paste the short
  version above after installing ClaudeMaxPower manually.

If a platform does not expose a Skill tool, replace every `/skill-name` reference with
"follow the workflow in `skills/skill-name.md`" and the assistant will still execute the
steps.

### Troubleshooting

**`git clone` fails.** Network issue or proxy blocking github.com. Try the tarball fallback
(`curl | tar -xz`). If that also fails, download the repo as a zip from
https://github.com/michelbr84/ClaudeMaxPower/archive/refs/heads/main.zip, extract it, and
run `bash scripts/setup.sh` manually.

**The target directory already has files.** The bootstrap uses `rsync --ignore-existing`
so user files are never overwritten. If you want a clean slate, move your code aside first
or install into a subdirectory (`./claudemaxpower/`) and integrate manually.

**The assistant doesn't respond as expected.** Most commonly the assistant truncated the
prompt or skipped steps. Resend the prompt as a single message (no attachments, no extra
context) and explicitly ask it to number its progress through steps 1 through 7. If it
still misbehaves, invoke `/max-power` directly once installed — the skill file is
deterministic and shorter to execute than the bootstrap prompt.

**Setup.sh warns about missing tools.** That is normal. `gh`, `jq`, and `graphviz` are
optional. Install them if you need `/fix-issue`, `/review-pr`, batch workflows, or
dependency graphs.

**`.env` placeholders are unfilled.** Open `.env` and fill in `GITHUB_TOKEN`,
`ANTHROPIC_API_KEY`, and any other keys the setup script flagged. Skills that need them
will tell you which is missing when they fail.

### What you get

After the bootstrap prompt runs cleanly, you unlock the full ClaudeMaxPower capability
surface:

- **Brainstorm gate** — `/brainstorming` forces a designed spec before any code is written
- **Spec-to-plan** — `/writing-plans` converts an approved spec into bite-sized tasks
- **Subagent-driven dev** — `/subagent-dev` runs each task in a fresh subagent with a
  two-stage implementer/reviewer handoff
- **Strict TDD** — `/tdd-loop` enforces RED-GREEN-REFACTOR; `/tdd-loop-lite` kept as a
  lighter option
- **Systematic debugging** — `/systematic-debugging` enforces reproduce-isolate-understand-fix
  before any bug patch
- **Worktree isolation** — `/using-worktrees` sets up isolated git worktrees so parallel
  agents never collide
- **Agent teams** — `/assemble-team` spawns a coordinated team (architect, implementer,
  tester, reviewer, doc writer for new projects; analyst, planner, parallel implementers,
  reviewer for existing projects)
- **Finish workflow** — `/finish-branch` offers merge / PR / keep / discard decisions at
  the end of a feature
- **Governance hooks** — session-start (context restore + Auto Dream), pre-tool-use
  (dangerous-command blocker + audit log), post-tool-use (auto-test on edit), stop
  (persist `.estado.md`)
- **Auto Dream** — background memory consolidation every 24h + 5 sessions keeps Claude's
  memory clean as projects grow
- **MCP integrations** — optional MCP servers for GitHub, Supabase, Vercel, and more work
  alongside the skills (see `docs/mcp-integrations.md`)

The single command `/max-power` (or the bootstrap prompt above) is how you turn all of this
on in one shot.
