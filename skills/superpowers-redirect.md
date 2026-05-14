---
name: superpowers-redirect
description: Use when user types /brainstorming, /writing-plans, /subagent-dev, /tdd-loop, /systematic-debugging, /using-worktrees, or /finish-branch — these moved to the Superpowers plugin. Routes the user to the canonical /superpowers:* command.
arguments: []
allowed-tools:
  - Read
---

# Skill: superpowers-redirect

ClaudeMaxPower no longer ships local copies of the Superpowers methodology skills. They are
installed via the official Superpowers plugin and invoked with the `/superpowers:` namespace.

## Mapping (old → new)

| Old slash command            | Canonical replacement                            |
|------------------------------|--------------------------------------------------|
| `/brainstorming`             | `/superpowers:brainstorming`                     |
| `/writing-plans`             | `/superpowers:writing-plans`                     |
| `/subagent-dev`              | `/superpowers:subagent-driven-development`       |
| `/tdd-loop`                  | `/superpowers:test-driven-development`           |
| `/systematic-debugging`      | `/superpowers:systematic-debugging`              |
| `/using-worktrees`           | `/superpowers:using-git-worktrees`               |
| `/finish-branch`             | `/superpowers:finishing-a-development-branch`    |

## If the plugin is not installed

Tell the user to install it:

```
/plugin install superpowers@claude-plugins-official
```

Then re-invoke the canonical `/superpowers:*` command from the table above.

## Workflow

1. Identify which old name the user typed.
2. Look up the canonical replacement in the table above.
3. Tell the user the exact `/superpowers:*` command to run, plus a one-line "why this moved"
   note: the methodology lives upstream so it tracks the canonical Superpowers version
   without local drift.
4. If the user is unsure whether the plugin is installed, give them the install line above.

**Feedback:** Did the redirect land you on the right command? Reply with a 1–10 rating or
suggest a faster path from where you started to where you ended.
