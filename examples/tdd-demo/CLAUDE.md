# tdd-demo — Subfolder Instructions

> Extends root CLAUDE.md. Rules here override root rules for this example only.

## Context

This directory demonstrates the `tdd-loop` skill: starting from only a specification,
Claude writes tests first, then iterates on the implementation until all tests are green.

## TDD Mandate

**NEVER write implementation code before writing tests.**

The workflow is strictly:
1. Read `spec.md`
2. Write failing tests in `tests/`
3. Run tests — expect red
4. Write minimal implementation in `src/`
5. Run tests — if still red, refine implementation
6. Repeat until all tests pass
7. Report

## Language and Stack

- **Language**: Python 3.10+
- **Test runner**: pytest (`python -m pytest tests/ -v`)
- **No mocks** — test against real in-memory state only

## Test Command

```
python -m pytest tests/ -v --tb=long
```

## File Structure

```
tdd-demo/
├── CLAUDE.md          ← you are here
├── spec.md            ← feature specification (read-only during TDD loop)
├── src/
│   └── calculator.py  ← implementation (written AFTER tests)
└── tests/
    └── test_calculator.py  ← tests (written FIRST)
```
