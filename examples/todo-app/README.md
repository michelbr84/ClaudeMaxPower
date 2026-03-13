# todo-app — ClaudeMaxPower Demo App

A minimal Python CLI todo list with **3 intentional bugs** — used as a testbed for ClaudeMaxPower skills.

## Purpose

This app exists to demonstrate:
- `fix-issue` skill — fixing GitHub issues with TDD
- `tdd-loop` skill — adding new features test-first
- `pre-commit` skill — catching issues before committing

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

# 2. Run tdd-loop to add a "search tasks" feature
/tdd-loop --spec "Add a search_tasks(query) function that returns tasks whose title contains the query string (case-insensitive)" --file src/todo.py

# 3. Run pre-commit before committing
/pre-commit
```
