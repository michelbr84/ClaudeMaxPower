# Parallel Workflows with Git Worktrees

Git worktrees let you check out multiple branches of the same repository simultaneously. Combined with Claude's headless mode, you can run multiple Claude sessions in parallel — each working on an isolated copy of the code.

## Why Worktrees?

Without worktrees, running two Claude sessions in the same directory means they interfere with each other's file changes. With worktrees:

- Each session has its own working directory
- Changes in one don't affect the other
- You can diff between worktrees easily

## The Writer/Reviewer Pattern

The most powerful parallel pattern: one session writes, another reviews.

```
Main repo                  Writer Worktree            Reviewer Worktree
(your work)                /tmp/writer-123/           /tmp/reviewer-123/
                               │                           │
                               ├── implements feature      ├── reads writer's diff
                               ├── writes tests            ├── checks correctness
                               └── commits changes         └── produces review
```

### Using the Built-in Script

```bash
./workflows/parallel-review.sh \
  --feature add-search \
  --task "Add search_tasks(query) function to examples/todo-app/src/todo.py with pytest tests"
```

This creates both worktrees, runs both sessions, and outputs a combined report.

### Manual Worktree Setup

```bash
# Create writer worktree
git worktree add -b feature-search /tmp/writer main

# Run writer session (headless)
claude --print \
  --allowedTools "Bash,Read,Edit,Write" \
  "Implement search_tasks() in /tmp/writer/examples/todo-app/src/todo.py. Write tests. Commit." \
  2>&1 | tee /tmp/writer-output.txt

# Get the diff
DIFF=$(git -C /tmp/writer diff main...feature-search)

# Create reviewer worktree
git worktree add /tmp/reviewer main

# Run reviewer session (headless)
claude --print \
  --allowedTools "Read,Grep" \
  "Review this diff: $DIFF" \
  2>&1 | tee /tmp/review.txt

# Cleanup
git worktree remove /tmp/writer
git worktree remove /tmp/reviewer
git branch -d feature-search
```

## Parallel Issue Processing

Run multiple issues simultaneously in separate worktrees:

```bash
#!/usr/bin/env bash
# Process 3 issues in parallel

for ISSUE in 10 11 12; do
  WORKTREE="/tmp/issue-$ISSUE-$$"
  BRANCH="fix/issue-$ISSUE"

  git worktree add -b "$BRANCH" "$WORKTREE" main

  # Run each in background
  (
    claude --print \
      --allowedTools "Bash,Read,Edit" \
      "Fix GitHub issue #$ISSUE following the fix-issue workflow" \
      > "/tmp/result-$ISSUE.txt" 2>&1
    echo "Issue #$ISSUE done"
  ) &
done

# Wait for all background jobs
wait
echo "All issues processed"

# Cleanup
for ISSUE in 10 11 12; do
  git worktree remove "/tmp/issue-$ISSUE-$$"
  git branch -d "fix/issue-$ISSUE" 2>/dev/null || true
done
```

## Worktree Commands Reference

```bash
# Add a new worktree on an existing branch
git worktree add /path/to/worktree branch-name

# Add a worktree with a new branch
git worktree add -b new-branch /path/to/worktree main

# List all worktrees
git worktree list

# Remove a worktree (must have no uncommitted changes)
git worktree remove /path/to/worktree

# Force remove (discard uncommitted changes)
git worktree remove --force /path/to/worktree

# Prune stale worktree references
git worktree prune
```

## When to Use Parallel Sessions

**Use parallel sessions when:**
- Multiple independent features can be developed simultaneously
- You want a reviewer that hasn't seen the code being reviewed
- Batch processing where tasks don't depend on each other
- You want to compare two different approaches to the same problem

**Don't use parallel sessions when:**
- Tasks depend on each other's output
- Changes need to be in a specific order
- You want a simple sequential workflow (overkill)

## Disk Space Considerations

Each worktree is a full checkout of the repository. For large repos:
- Worktrees share the `.git` object store (not duplicated)
- But the working files are duplicated
- Clean up worktrees when done: `git worktree remove`
