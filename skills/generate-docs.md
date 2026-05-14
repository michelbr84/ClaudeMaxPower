---
name: generate-docs
description: Auto-generate documentation from source code — extracts public APIs and creates or updates markdown docs.
arguments:
  - name: dir
    description: Directory to scan for source files
    required: true
  - name: output
    description: Output directory for docs (default: docs/)
    required: false
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

# Skill: generate-docs

Scan source files and generate or update structured markdown documentation.

## Arguments

- `--dir <directory>` — source directory to scan (required)
- `--output <dir>` — where to write docs (optional, defaults to `docs/`)

## Workflow

### Step 0: Validate prerequisites

- If `--dir` is missing or not a readable directory, **stop and ask the user**: "Which
  directory should I scan?"
- Resolve the output directory (`--output` or default `docs/api/`). If it doesn't exist,
  attempt to create it; if the parent isn't writable, ask the user for an alternative path.
- Detect the dominant stack of `--dir`: count `.py` vs `.ts`/`.tsx`/`.js`/`.jsx` files.
  Pick the helper script for the dominant stack (or run both if the directory is mixed).

### Step 1: Discover source files and extract public API

Run the helper script for the detected stack — these live in `skills/references/` so the
extraction logic can be tuned independently of this skill:

```bash
# Python
bash skills/references/extract-api-python.sh "$DIR"

# TypeScript/JavaScript
bash skills/references/extract-api-typescript.sh "$DIR"
```

Each helper outputs one line per definition: `<file>:<line>:<signature>`.

For each definition reported:
- **Python**: include the existing docstring (read the file, capture the triple-quoted block
  immediately after the `def`/`class`).
- **TypeScript/JavaScript**: include the JSDoc block (the `/** ... */` immediately above the
  `export`).
- Skip any name starting with `_` (Python convention) or marked `@internal` (JSDoc).

### Step 2: Generate missing docstrings (in-source)
For any public function/class missing documentation:
1. Infer purpose from the function name and body.
2. Add a docstring directly to the source file (Python: `"""..."""`, JS: `/** ... */`).
3. Only add docstrings — do not change logic.

### Step 3: Create or update docs files

For each source file `src/foo.py`, create or update `docs/api/foo.md`:

```markdown
# foo

> <one-line description of the module>

## Functions

### `function_name(param1: type, param2: type) -> return_type`

<docstring content>

**Parameters:**
- `param1` — description
- `param2` — description

**Returns:** description

**Example:**
\```python
result = function_name(arg1, arg2)
\```

---
```

### Step 4: Update docs index
Update or create `docs/api/README.md` with a table of all documented modules:

```markdown
# API Reference

| Module | Description |
|--------|-------------|
| [foo](foo.md) | <one-liner> |
| [bar](bar.md) | <one-liner> |
```

### Step 5: Report
Tell the user:
- Files scanned: N
- Functions/classes documented: M
- Docstrings added (in-source): K
- Docs files created: X
- Docs files updated: Y
- Output location: `docs/api/`

**Feedback:** Did this skill do what you needed? Reply with a 1–10 rating, what slowed you
down, or a faster path from where you started to where you ended.
