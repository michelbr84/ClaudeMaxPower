# Auto Dream Guide

Auto Dream is ClaudeMaxPower's memory consolidation system — inspired by how the human brain
consolidates memories during REM sleep. It keeps your Claude memory files clean, relevant, and
well-organized across long-lived projects.

## The Problem

Claude Code's auto memory is powerful, but over many sessions it accumulates:
- **Stale memories** — references to files, functions, or decisions that no longer exist
- **Contradictions** — newer memories that override older ones without removing them
- **Duplicates** — the same fact saved multiple times with slightly different wording
- **Vague references** — "today", "this week", "recently" that lose meaning over time
- **Bloated index** — MEMORY.md grows past its 200-line effective limit

The result: Claude starts performing *worse* as memory grows, because noisy context drowns out
the signal.

## How Auto Dream Works

Auto Dream runs as a background process triggered by the session-start hook. It mimics REM
sleep consolidation:

### Trigger Conditions

Both conditions must be met:
1. **24+ hours** since the last dream
2. **5+ sessions** since the last dream

This ensures dreams run frequently enough to stay fresh, but not so often they waste resources.

### Consolidation Phases

| Phase | What It Does |
|-------|-------------|
| **1. Inventory** | Scans all `.md` files in the memory directory |
| **2. Staleness Check** | Flags files older than 30 days, finds relative date references |
| **3. Duplicate Detection** | Finds memories with identical names or overlapping content |
| **4. Index Rebuild** | Reconstructs MEMORY.md grouped by type (user, feedback, project, reference) |
| **5. State Update** | Records dream timestamp and resets session counter |

### Safety Guarantees

- **Read-only on project code** — Auto Dream never touches your source files
- **Write access to memory only** — Only modifies files in the memory directory
- **Lock file protection** — Prevents two instances from running simultaneously
- **Graceful degradation** — If anything fails, it exits cleanly without corruption

## Configuration

Auto Dream uses environment variables for configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MEMORY_DIR` | Auto-detected | Path to the memory directory |
| `CLAUDE_PROJECT_DIR` | Current directory | Project root for context |

Timing constants are in `scripts/auto-dream.sh`:

```bash
MIN_HOURS_BETWEEN_DREAMS=24
MIN_SESSIONS_BETWEEN_DREAMS=5
```

## Integration with Session Start

Auto Dream is triggered by the session-start hook. When a new session opens:

1. `session-start.sh` runs its normal startup (git context, estado, skills list)
2. It then calls `scripts/auto-dream.sh` in the background
3. Auto Dream checks if consolidation is needed
4. If yes, it runs silently and updates the memory state
5. The next time Claude reads MEMORY.md, it gets a clean, consolidated index

## State File

Auto Dream tracks its state in `.dream-state.json` inside the memory directory:

```json
{
  "last_dream_epoch": 1711526400,
  "sessions_since": 0,
  "last_check": "2026-03-27T10:00:00Z",
  "files_processed": 12,
  "stale_found": 2,
  "duplicates_found": 1
}
```

## Manual Invocation

You can run Auto Dream manually:

```bash
CLAUDE_MEMORY_DIR="$HOME/.claude/projects/your-project/memory" bash scripts/auto-dream.sh
```

Or ask Claude:
```
Run Auto Dream now — consolidate my memory files.
```

## What Auto Dream Does NOT Do

Auto Dream handles the mechanical aspects of memory hygiene. It does **not**:

- Rewrite memory content (that requires Claude's understanding)
- Delete memories automatically (it flags, Claude decides)
- Merge contradictory memories (it detects, Claude resolves)
- Create new memories from patterns it finds

For deeper consolidation that requires semantic understanding, Claude itself reviews the
flagged items during the next session and makes intelligent decisions about merging,
updating, or removing memories.

## Future: Deep Dream

A planned enhancement where Claude actively:
1. Reads all memory files and session transcripts
2. Identifies patterns across sessions
3. Rewrites stale memories with current information
4. Merges related memories into consolidated entries
5. Removes memories that are now captured in code or docs

This requires a dedicated Claude session (`claude --print`) and is designed for
overnight/weekend execution on large projects.
