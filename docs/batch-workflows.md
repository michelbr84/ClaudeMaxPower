# Batch Workflows

Batch workflows run Claude in headless mode (`claude --print`) to process multiple tasks autonomously — no interactive session required.

## How Headless Mode Works

```bash
claude --print "Fix the bug in src/foo.py" \
  --allowedTools "Bash,Read,Edit" \
  --output-format json
```

- `--print` / `-p`: Run non-interactively, print output and exit
- `--allowedTools`: Restrict which tools Claude can use (security)
- `--output-format json`: Machine-readable output for scripting

Claude reads the prompt, executes the task, and exits. You can chain these calls in a loop.

## Available Workflow Scripts

### batch-fix.sh

Fix multiple GitHub issues in sequence, each getting its own Claude session.

```bash
./workflows/batch-fix.sh owner/repo 10 11 12 13
```

**What it does:**
1. For each issue number: runs `claude --print` with the fix-issue workflow
2. Logs each result (success/failure + output) to `batch-results.json`
3. Prints a summary at the end

**When to use:** You have a backlog of similar bugs and want to process them overnight.

**Output:** `batch-results.json` — structured results per issue.

---

### mass-refactor.sh

Apply a refactoring goal across all files matching a pattern.

```bash
# Rename a function across the entire codebase
./workflows/mass-refactor.sh \
  --pattern "get_user_by_id" \
  --goal "rename to fetch_user and add type hints"

# Target a specific directory
./workflows/mass-refactor.sh \
  --pattern "conn.execute" \
  --goal "use parameterized queries instead of string formatting" \
  --dir src/
```

**What it does:**
1. `grep -rl <pattern>` finds all matching files
2. For each file: Claude reads, applies the refactor, runs nearby tests
3. `git diff --stat` summary at the end

**Safety:** Prompts for confirmation if more than 20 files are affected.

---

### parallel-review.sh

Writer/Reviewer pattern — two separate Claude sessions, isolated in git worktrees.

```bash
./workflows/parallel-review.sh \
  --feature add-search \
  --task "Add search_tasks(query) function to todo.py with tests"
```

**What it does:**
1. Creates a git worktree for the Writer session
2. Writer implements the feature in isolation
3. Gets the diff from the Writer's worktree
4. Reviewer (second session) reads the diff and produces a structured review
5. Outputs combined report (diff + review)

**Why worktrees:** Both sessions work simultaneously without interfering with your working directory or each other.

**See also:** [Parallel Workflows with Worktrees](worktrees-parallel.md)

---

### dependency-graph.sh

Generate a visual dependency graph of your source files.

```bash
./workflows/dependency-graph.sh --dir src/ --output docs/deps.svg
```

**What it does:**
1. Claude analyzes import statements across source files
2. Generates a `.dot` file (Graphviz format)
3. Converts to SVG (requires `graphviz` installed)

**Requires:** `graphviz` — `brew install graphviz` or `apt install graphviz`

---

## Writing Your Own Batch Script

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="$1"

while IFS= read -r ITEM; do
  claude --print \
    --allowedTools "Read,Edit,Bash" \
    --output-format json \
    "Process this item: $ITEM" >> results.json
done < "$INPUT_FILE"
```

**Best practices:**
- Use `--allowedTools` to restrict Claude to only what's needed
- Use `--output-format json` for machine-readable output
- Log results as you go (don't wait until the end)
- Handle failures per-item — one bad item shouldn't stop the batch
- Test with 1 item before running 100

## Rate Limits and Cost

Each `claude --print` call counts as a separate Claude session. For large batches:
- Add a small delay between calls if you hit rate limits
- Monitor your API usage
- For very large batches (100+ items), consider running overnight

## Using with CI/CD

Batch scripts work in GitHub Actions:

```yaml
- name: Batch process issues
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    bash workflows/batch-fix.sh ${{ github.repository }} ${{ env.ISSUE_NUMBERS }}
```
