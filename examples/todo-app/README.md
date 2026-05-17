# todo-app — ClaudeMaxPower Demo App

A minimal Python CLI todo list with **3 intentional bugs** — used as a testbed for ClaudeMaxPower skills.

## Purpose

This app exists to demonstrate:
- `/fix-issue` skill — fixing GitHub issues with TDD
- `/superpowers:test-driven-development` (upstream Superpowers) — adding new features test-first
- the `pre-commit-check.sh` hook — catches secrets / debug code / large files automatically before every `git commit`, with `/gen-commit-message` for the message itself

## The Bugs (for skill demonstrations)

| Issue | Location | Bug |
|-------|----------|-----|
| #1 | `delete_task()` | Off-by-one error: deletes wrong task when ID > 1 |
| #2 | `complete_task()` | Always marks first task as done, ignores task_id |
| #3 | `list_tasks()` | Sorts ascending instead of descending by priority |

## Running the Tests

```bash
cd examples/todo-app
python -m pytest tests/ -v
```

You'll see the 3 buggy tests fail. That's expected — use the skills to fix them!

## Demo Workflow

```bash
# 1. Run fix-issue skill to fix bug #1
/fix-issue --issue 1 --repo your-username/ClaudeMaxPower

# 2. Run the upstream Superpowers TDD loop to add a "search tasks" feature
#    (one-time install: /plugin install superpowers@claude-plugins-official)
/superpowers:test-driven-development "Add a search_tasks(query) function in src/todo.py that returns tasks whose title contains the query string (case-insensitive)"

# 3. Commit — the pre-commit-check.sh hook runs automatically (secrets, debug
#    statements, large files, linter). Use /gen-commit-message for the message.
/gen-commit-message
git commit
```
