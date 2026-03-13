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

### Step 1: Discover source files
```bash
# Python
find $DIR -name "*.py" -not -path "*/test*" -not -name "__init__.py"

# JavaScript/TypeScript
find $DIR -name "*.ts" -o -name "*.js" -not -path "*/node_modules/*" -not -name "*.test.*"
```

List all source files found.

### Step 2: Extract public API from each file

For each source file:
- **Python**: extract all `def` and `class` definitions that don't start with `_`
  - Include existing docstrings if present
  - Include function signatures (parameters + type hints)
- **JavaScript/TypeScript**: extract all `export function`, `export class`, `export const`
  - Include JSDoc comments if present
  - Include TypeScript type signatures

### Step 3: Generate missing docstrings (in-source)
For any public function/class missing documentation:
1. Infer purpose from the function name and body
2. Add a docstring directly to the source file (Python: `"""..."""`, JS: `/** ... */`)
3. Only add docstrings — do not change logic

### Step 4: Create or update docs files

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

### Step 5: Update docs index
Update or create `docs/api/README.md` with a table of all documented modules:

```markdown
# API Reference

| Module | Description |
|--------|-------------|
| [foo](foo.md) | <one-liner> |
| [bar](bar.md) | <one-liner> |
```

### Step 6: Report
Tell the user:
- Files scanned: N
- Functions/classes documented: M
- Docstrings added (in-source): K
- Docs files created: X
- Docs files updated: Y
- Output location: `docs/api/`
