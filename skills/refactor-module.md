---
name: refactor-module
description: Safely refactor a module — captures a test baseline first, applies the refactor, then verifies all tests still pass.
arguments:
  - name: file
    description: Path to the file to refactor
    required: true
  - name: goal
    description: Description of the refactoring goal (e.g. "extract validation logic into a separate function")
    required: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

# Skill: refactor-module

Safely refactor a module with test-backed confidence. Never leaves tests in a worse state.

## Arguments

- `--file <path>` — file to refactor (required)
- `--goal <description>` — what to achieve with this refactor (required)

## Workflow

### Step 1: Read the file
Read the full implementation file. Understand:
- Public API (functions, classes, exports)
- Internal structure and dependencies
- Any TODOs or known issues

### Step 2: Find and read the test file
Look for a corresponding test file:
```bash
# Examples: tests/test_foo.py, __tests__/foo.test.ts, foo.spec.js
```
If no test file exists, stop and tell the user. A refactor without tests is risky.

### Step 3: Capture test baseline
```bash
python -m pytest <test-file> -v --tb=short 2>&1 | tee /tmp/baseline-results.txt
```
Record:
- Total tests: X passed, Y failed (note: Y should be 0 before refactoring)
- Test names

If tests are already failing before refactoring, stop and tell the user. Fix existing failures first.

### Step 4: Plan the refactor
Based on `--goal`, identify:
- What changes are needed (extract function, rename, split class, etc.)
- What should NOT change (public API, behavior, test assertions)
- Order of changes to minimize breakage

### Step 5: Apply the refactor
Make targeted changes using the Edit tool. Prefer:
- Small, incremental edits
- Rename in all call sites (use Grep to find all usages)
- Keep public API intact unless the goal explicitly requires changing it

### Step 6: Run tests after refactor
```bash
python -m pytest <test-file> -v --tb=short
```

If any tests fail:
1. Read the failure output carefully
2. Determine if it's a refactor error or a legitimate issue uncovered
3. Fix the refactor error (not the test)
4. Re-run until green

### Step 7: Update documentation if needed
If the refactor changed any public API:
- Update docstrings in the implementation
- Update any relevant docs/ pages

### Step 8: Report
Tell the user:
- What was refactored
- What changed in the public API (if anything)
- Final test results (before vs. after comparison)
- Any issues discovered during refactoring
