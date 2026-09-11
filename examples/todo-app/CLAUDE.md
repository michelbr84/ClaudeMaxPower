# todo-app — Subfolder Instructions

> Extends root CLAUDE.md. Rules here override root rules for this example only.

## Context

This is a minimal Python CLI todo app used as a testbed for ClaudeMaxPower skills.
It has intentional bugs pre-seeded so that the `fix-issue` and `tdd-loop` skills can be demonstrated.

## Language and Stack

- **Language**: Python 3.10+
- **Test runner**: pytest (`python -m pytest tests/ -v`)
- **Linter**: flake8 (`flake8 src/ tests/`)
- **No external dependencies** beyond pytest and flake8

## Test Command

Always run tests with:
```
python -m pytest tests/ -v --tb=short
```

Tests must pass before any commit. Do not skip or xfail tests to make them pass.

## Known Intentional Bugs (for demo purposes)

- Issue #1: `todo.py` — `delete_task()` has an off-by-one error: pops `i - 1` instead of `i`
- Issue #2: `todo.py` — `complete_task()` ignores the requested ID: it always marks the first task done and returns True even for nonexistent IDs
- Issue #3: `todo.py` — `list_tasks()` sorts by priority ascending (lowest first) instead of descending

These bugs exist to demonstrate the `fix-issue` skill. Do not fix them unless running the skill demo.

## File Structure

```
todo-app/
├── CLAUDE.md          ← you are here
├── src/
│   └── todo.py        ← main implementation
├── tests/
│   └── test_todo.py   ← pytest test suite
└── requirements.txt
```
