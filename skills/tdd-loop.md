---
name: tdd-loop
description: Autonomous TDD loop — writes failing tests from a spec, then iterates on implementation until all tests are green. Stops at 10 iterations.
arguments:
  - name: spec
    description: Feature specification (plain English description of what to build)
    required: true
  - name: file
    description: Path to the implementation file to create or update
    required: true
  - name: test-file
    description: Path to the test file (auto-derived from --file if not provided)
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

# Skill: tdd-loop

Write tests first, then implement until green. Strict Red → Green → Refactor cycle.

## Arguments

- `--spec <description>` — what to build, in plain English (required)
- `--file <path>` — implementation output file (required)
- `--test-file <path>` — test file path (optional, auto-derived from `--file`)

## Workflow

### Step 1: Read the spec
Parse `--spec` to understand:
- What functions/classes/behavior is needed
- Input/output contracts
- Edge cases explicitly mentioned
- What is NOT in scope

If `--spec` points to a file (e.g. `spec.md`), read that file.

### Step 2: Derive test file path
If `--test-file` not provided:
- Python: `src/foo.py` → `tests/test_foo.py`
- JavaScript: `src/foo.js` → `__tests__/foo.test.js`
- TypeScript: `src/foo.ts` → `__tests__/foo.test.ts`

### Step 3: Write tests (RED phase)
Write comprehensive tests covering:
- Happy path (normal inputs)
- Edge cases (empty, zero, boundary values)
- Error cases (invalid inputs, exceptions expected)

**Important**: Do NOT write any implementation yet. The goal is a failing test suite.

```bash
python -m pytest <test-file> -v --tb=short 2>&1
# Expected: all tests FAIL (that's correct at this stage)
```

Confirm tests are RED. If they accidentally pass, the tests may not be testing the right thing.

### Step 4: Implement (GREEN phase) — Iteration 1
Write the minimal implementation that could possibly make the tests pass.
- Do not over-engineer
- Do not add features not in the spec
- Use simple, direct code

```bash
python -m pytest <test-file> -v --tb=short 2>&1
```

### Step 5: Iterate until GREEN
For each failing test:
1. Read the error message carefully
2. Identify what the implementation is missing
3. Fix only what's needed to pass this test
4. Re-run

**Maximum iterations: 10.** If still failing after 10 iterations, stop and report what's blocking.

Track iteration count:
```
Iteration 1: X/Y tests passing
Iteration 2: X+n/Y tests passing
...
```

### Step 6: Refactor (REFACTOR phase)
Once all tests are GREEN:
- Clean up any messy implementation code
- Extract helpers if there's obvious duplication
- Add docstrings/type hints
- Run tests one final time to confirm still GREEN

### Step 7: Final report
Tell the user:
- Total iterations needed: N
- Tests written: X
- Final result: all X tests passing
- Any notable implementation decisions
- Suggestions for additional edge cases not covered
