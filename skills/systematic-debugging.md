---
name: systematic-debugging
description: Four-phase root cause debugging process. Never propose a fix without a failing test and a verified root cause.
arguments:
  - name: issue
    description: Description of the bug, error message, or failing test
    required: true
  - name: file
    description: File or area to focus investigation on
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

# Skill: systematic-debugging

> **Attribution:** Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License). Original skill: `superpowers:systematic-debugging`. See `ATTRIBUTION.md`.

A disciplined four-phase process for finding and eliminating the actual cause of a defect —
not a symptom, not a near-miss, not a guess that happens to quiet the alarm.

## The Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you have not completed Phase 1, you may not propose fixes. No exceptions. If time pressure
is tempting you to skip phases, that is the strongest possible signal that you need the process.

## When to Use

Use this skill for any technical issue:
- Test failures (unit, integration, end-to-end)
- Bugs reported in production
- Unexpected behavior or wrong output
- Performance regressions
- Build or deployment failures
- Flaky tests

Use it **especially** when:
- You are under time pressure ("we need to ship")
- A "just one quick fix" feels obvious (that feeling is the bias you are trying to beat)
- A previous fix did not stick and the symptom returned
- Multiple engineers have already tried and failed

## Workflow

### Phase 1: Root Cause Investigation

The goal is understanding, not repair. Do not touch production code yet.

#### Step 1.1: Read error messages carefully
Do not skim. Read every line of the failure output. Note exact file paths, line numbers, stack
frames, and error codes. Errors almost always say exactly what is wrong — the reader just has
to actually read them.

#### Step 1.2: Reproduce consistently
Write down the exact steps that trigger the issue. Can you reproduce it every time? If the
reproduction is intermittent, that is a first-class piece of evidence — investigate what makes
it sometimes work.

```bash
# Capture the exact reproduction command
./run-repro.sh 2>&1 | tee /tmp/repro.log
```

#### Step 1.3: Check recent changes
```bash
git log --oneline -20
git diff HEAD~5 -- <suspect-file>
git log -p --since="2 days ago"
```
Ask: what changed recently near the failing area?

#### Step 1.4: Instrument component boundaries
In multi-component systems (web + worker, client + server, library + caller) add diagnostic
instrumentation at **every layer boundary** before proposing any fix. Knowing which boundary
loses or mutates the data is the whole game.

```bash
# Example: trace a value through four layers
echo "=== Layer 1: HTTP handler ===" ; curl -v http://localhost:3000/api/task
echo "=== Layer 2: Service layer ===" ; grep -n "taskId" app/services/*.ts
echo "=== Layer 3: Repository ===" ; grep -n "taskId" app/repos/*.ts
echo "=== Layer 4: DB query log ===" ; tail -f /var/log/postgres.log
```

Do **not** remove this instrumentation until the root cause is confirmed.

#### Step 1.5: Trace backward from the symptom
Start at the visible symptom and walk backward along the data flow until you reach the earliest
point where the value, state, or control flow first goes wrong. That point — not the first
place it becomes visible — is the root cause candidate.

### Phase 2: Pattern Analysis

The goal is context — understanding what "correct" looks like right next to what is broken.

#### Step 2.1: Find working examples
Is there similar code elsewhere in the project that works? Find it with Grep. Any test that
exercises a sibling path?

#### Step 2.2: Compare against references
Read the working code **completely**. Do not skim. Skimming is how you miss the exact line
that makes the difference.

#### Step 2.3: List every difference
Side by side, enumerate every difference between the broken and working paths — ordering,
arguments, error handling, config, environment, types. Even differences that "couldn't possibly
matter" go on the list. They often matter.

#### Step 2.4: Understand dependencies
What config, environment variables, feature flags, database state, or external service
assumptions does the broken code rely on? Verify each is actually present and correct in the
failing environment.

### Phase 3: Hypothesis and Testing

The goal is a single testable explanation.

#### Step 3.1: Form a single hypothesis
Write it down in this exact shape:

> "I think **X** is the root cause because **Y**."

One hypothesis. Not a shopping list.

#### Step 3.2: Test minimally
The smallest possible probe that confirms or refutes the hypothesis. Change one variable at a
time. If the probe needs more than one change, your hypothesis is too big — split it.

#### Step 3.3: Verify before continuing
If the probe confirmed the hypothesis: proceed to Phase 4.
If the probe refuted it: form a **new** hypothesis. Do not pile additional guesses on top of
a disproven one. Do not "fix" anything yet.

#### Step 3.4: Admit uncertainty
If you do not know, say so. Write "I do not know why X happens" in the investigation notes.
Pretending certainty you do not have is how wrong fixes ship.

### Phase 4: Implementation

The goal is a durable fix backed by a test.

#### Step 4.1: Create a failing test case FIRST
Before touching production code, write a test that fails for the exact reason the bug exists.
This test is the contract that the bug does not return. For proper TDD scaffolding, invoke
`/tdd-loop` with a spec derived from the root cause.

```bash
# Run the new test and confirm it fails for the right reason
pytest tests/test_regression_<issue>.py -v
# Expected: FAIL with the same error signature as the original bug
```

#### Step 4.2: Implement a single fix
**One** change. No "while I'm here" refactors. No bonus improvements. No unrelated cleanups.
Those go in separate commits after the regression is closed.

#### Step 4.3: Verify the fix
Three checks, all mandatory:

1. The new regression test passes.
2. The full test suite still passes — no other tests broken.
3. The original reproduction no longer reproduces the issue.

```bash
pytest tests/test_regression_<issue>.py -v   # 1
pytest                                        # 2
./run-repro.sh                                # 3
```

### When fixes keep failing

If three or more fix attempts have failed, **stop**. You are no longer debugging — you are
thrashing. This pattern indicates an architectural problem, not a local bug.

Patterns that mean "the architecture is the bug":
- Each fix reveals new shared state or coupling you did not know existed
- Fixes require "massive refactoring" to work correctly
- Each fix creates a new symptom somewhere else in the system
- The same conceptual bug reappears in multiple files

When you hit this, discuss with the user before the fourth attempt. The correct next move is
usually a design change, not another patch.

## Red Flags

| Rationalization | Rebuttal |
|-----------------|----------|
| "Issue is simple, don't need process" | Simple issues have root causes too — the process takes minutes for simple bugs. |
| "Emergency, no time" | Systematic is faster than thrashing. Every failed guess doubles the timeline. |
| "Just try this first" | The first fix sets the pattern. If it is a guess, every subsequent step compounds the guess. |
| "I'll write the test after" | Untested fixes don't stick. The bug returns in a week and you re-debug from scratch. |
| "One more fix attempt" (after two failed) | Three failures means architectural problem. Stop and escalate. |
| "I can see the fix already" | You can see **a** fix. Phase 1 tells you whether it is **the** fix. |
| "The test is flaky, not broken" | Flakiness is a symptom. Investigate the race or timing issue — do not retry-loop around it. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|----------------|------------------|
| 1. Root Cause | Read errors, reproduce, instrument boundaries, trace backward | Single earliest point where state goes wrong is identified |
| 2. Pattern Analysis | Find working examples, list every difference, map dependencies | Written side-by-side comparison of broken vs working |
| 3. Hypothesis | Form one testable explanation, probe minimally | Hypothesis confirmed or refuted with evidence |
| 4. Implementation | Failing test first, single fix, triple verification | New test passes, full suite green, repro gone |

## Supporting Techniques

- **root-cause-tracing** — walking backward from symptom to source through the data flow
- **defense-in-depth** — adding redundant validations at layer boundaries so the same class of
  bug cannot recur undetected
- **condition-based-waiting** — replacing `sleep()` in flaky tests with explicit wait-for-state
  loops that capture the real precondition

## Integration with ClaudeMaxPower

- Works with `/tdd-loop` — Phase 4 Step 4.1 delegates regression-test creation to the TDD loop
- Pairs with the `code-reviewer` agent — after the fix is in, the reviewer verifies nothing
  else regressed and the change matches project conventions
- The `pre-tool-use.sh` hook's audit log is a useful Phase 1 artifact — it captures the exact
  commands leading up to the failure
- Fits inside `/fix-issue` as its investigation backbone — `/fix-issue` calls this skill when
  the bug is not trivial
