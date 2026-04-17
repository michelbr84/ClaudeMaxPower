---
name: tdd-loop
description: Strict Test-Driven Development — iron law enforcement, mandatory RED verification, anti-rationalization guardrails. Write the test first, watch it fail, write minimal code to pass.
arguments:
  - name: spec
    description: Feature specification (plain English description or path to spec file)
    required: true
  - name: file
    description: Path to implementation file
    required: true
  - name: test-file
    description: Path to test file (auto-derived if omitted)
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

> **Attribution:** Enhanced with methodology from [obra/superpowers](https://github.com/obra/superpowers) (MIT License). Original skill: `superpowers:test-driven-development`. See `ATTRIBUTION.md`.

> Looking for the simpler version? See `/tdd-loop-lite`.

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

Core principle: If you didn't watch the test fail, you don't know if it tests the right thing.

"Violating the letter of the rules is violating the spirit of the rules."

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. No exceptions:
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

## When to use

Always:
- New features
- Bug fixes
- Refactoring
- Behavior changes

Exceptions (ask the user):
- Throwaway prototypes
- Generated code
- Configuration files

## Arguments

- `--spec <description|path>` — what to build, in plain English, or path to a spec file (required)
- `--file <path>` — implementation output file (required)
- `--test-file <path>` — test file path (optional, auto-derived from `--file`)

## Workflow

### Step 1: Read the spec

Parse `--spec` to understand:
- What functions/classes/behavior is needed
- Input/output contracts
- Edge cases explicitly mentioned
- What is NOT in scope

If `--spec` points to a file (e.g. `docs/specs/foo-design.md`), read that file.

### Step 2: Derive test file path

If `--test-file` not provided:
- Python: `src/foo.py` → `tests/test_foo.py`
- JavaScript: `src/foo.js` → `__tests__/foo.test.js`
- TypeScript: `src/foo.ts` → `__tests__/foo.test.ts`

### Step 3: RED — Write one failing test

Requirements:
- ONE behavior per test
- Clear, descriptive name
- Real code paths (no mocks unless unavoidable)

Do NOT write ALL tests at once — write ONE test for ONE behavior at a time. Complete a full RED → GREEN → REFACTOR cycle before adding the next test.

**Good example** (tests real behavior):

```python
def test_counter_increments_by_one():
    counter = Counter(start=0)
    counter.increment()
    assert counter.value == 1
```

**Bad example** (tests mock behavior, vague name):

```python
def test_counter():
    mock = MagicMock()
    mock.increment.return_value = 1
    assert mock.increment() == 1  # Tests nothing real
```

### Step 4: MANDATORY — Verify RED (watch it fail)

Never skip this step. Run the test:

```bash
# Python
python -m pytest tests/test_foo.py::test_counter_increments_by_one -v

# JavaScript / TypeScript
npx jest __tests__/foo.test.js -t "counter increments by one"
```

Confirm:
- The test **fails** (not errors out)
- The failure message is expected — it fails because the feature is missing, not because of typos, import errors, or syntax mistakes
- If the test **passes immediately**: YOU ARE TESTING EXISTING BEHAVIOR. The test is wrong. Fix the test, don't move on.
- If the test **errors** (ImportError, SyntaxError, NameError before assertion): fix the error, re-run until it fails correctly on the assertion.

You must be able to state in one sentence why the test failed. If you can't, stop and re-read the output.

### Step 5: GREEN — Minimal implementation

Write the simplest possible code that passes ONLY this test.

Rules:
- Don't add features not exercised by the test
- Don't refactor unrelated code
- Don't "improve" beyond what the test requires
- YAGNI — ruthlessly

**Good example** (just enough to pass):

```python
class Counter:
    def __init__(self, start=0):
        self.value = start

    def increment(self):
        self.value += 1
```

**Bad example** (over-engineered, speculative features):

```python
class Counter:
    def __init__(self, start=0, step=1, max_value=None, options=None):
        self.value = start
        self.step = step
        self.max_value = max_value
        self.options = options or {}
        self.history = []

    def increment(self, amount=None):
        amount = amount or self.step
        self.history.append(self.value)
        self.value += amount
        if self.max_value and self.value > self.max_value:
            raise ValueError("exceeded max")
```

### Step 6: MANDATORY — Verify GREEN (watch it pass)

Run tests:

```bash
python -m pytest tests/test_foo.py -v --tb=short
```

Confirm:
- **This** test passes
- **All other** tests still pass (no regressions)
- Output is **pristine** — no warnings, no errors, no deprecation notices
- If the test fails → fix the **CODE**, never the test
- If other tests break → fix them **now**, don't defer

### Step 7: REFACTOR — Clean up

Only after GREEN:
- Remove duplication
- Improve names
- Extract helpers
- Add type hints / docstrings where appropriate

Rules:
- Keep tests green at every refactor step
- Do NOT add new behavior during refactor
- If you want new behavior, go back to Step 3 with a new test

### Step 8: Repeat

Write the next failing test for the next behavior. Cycle through RED → GREEN → REFACTOR again. Continue until the spec is fully covered.

## Anti-Rationalization Table (the 12 excuses)

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what SHOULD this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is tech debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard to write = design unclear" | Listen to the test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for the existing code. |
| "This is different because..." | It isn't. |

## Red Flags — STOP and Start Over

If any of the following is true, delete the code and restart with TDD:

- Code written before the test
- Test written after implementation
- Test passes the first time it's run
- Can't explain why the test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "It's about spirit not ritual"

## Testing Anti-Patterns

Avoid these — they produce tests that pass without proving anything:

- **Testing mock behavior instead of real behavior** — asserting that a mock returned the value you told it to return proves nothing about your code.
- **Adding test-only methods to production classes** — if you need a backdoor to test a class, the class is designed wrong. Refactor instead.
- **Mocking without understanding dependencies** — mocks that diverge from real behavior hide bugs. Only mock at true external boundaries (network, filesystem, clock), and verify behavior against real implementations when possible.

## Debugging integration

If a bug is found during development:
1. Write a failing test that **reproduces** the bug first
2. Verify RED (it fails because of the bug)
3. Fix the code
4. Verify GREEN (bug is gone, no regressions)

Never fix bugs without a test. See `/systematic-debugging` for the full root-cause process.

## Iteration tracking (ClaudeMaxPower extension)

This skill tracks progress and reports at the end:
- Total tests written
- Total iterations per test (max 10)
- Total iterations across all tests (max 25)
- If blocked: stop and report what's preventing progress — do NOT silently give up
- Suggestions for edge cases not yet covered

Example progress log:

```
Test 1 (counter_increments_by_one): RED ✓ | GREEN in 1 iteration
Test 2 (counter_rejects_negative): RED ✓ | GREEN in 2 iterations
Test 3 (counter_persists_state):   RED ✓ | blocked after 10 iterations — reason: missing storage layer
```

## Verification Checklist

Before marking work complete, confirm:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for the expected reason (not a typo or import error)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass, output is pristine
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

## Integration with ClaudeMaxPower

- Called by `/subagent-dev` for per-task TDD
- Pairs with `/systematic-debugging` (create failing test in Phase 4)
- Called by `/fix-issue` after reading the issue
- See `/tdd-loop-lite` for the simpler version
