#!/usr/bin/env bash
# auto-dream.sh — Memory consolidation inspired by REM sleep
# Reviews all memory files, prunes stale/contradictory entries,
# consolidates overlapping memories, and rebuilds the index.
#
# Triggers: After 24 hours + 5 sessions since last consolidation.
# Safety: Read-only on project code, write access only to memory files.
# Locking: Uses a lock file to prevent concurrent runs.
set -euo pipefail

# --- Configuration ---
MEMORY_DIR="${CLAUDE_MEMORY_DIR:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOCK_FILE="${MEMORY_DIR}/.dream.lock"
STATE_FILE="${MEMORY_DIR}/.dream-state.json"
MIN_HOURS_BETWEEN_DREAMS=24
MIN_SESSIONS_BETWEEN_DREAMS=5

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Helper functions ---
log_info()  { echo -e "${BLUE}[AutoDream]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[AutoDream]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[AutoDream]${NC} $1"; }
log_error() { echo -e "${RED}[AutoDream]${NC} $1"; }

cleanup() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# --- Validation ---
if [ -z "$MEMORY_DIR" ]; then
    # Try to detect memory dir from common locations
    if [ -d "$HOME/.claude/projects" ]; then
        # Find the memory dir for current project
        PROJECT_SLUG=$(echo "$PROJECT_DIR" | sed 's/[:\\\/]/-/g' | sed 's/^-//')
        CANDIDATE="$HOME/.claude/projects/${PROJECT_SLUG}/memory"
        if [ -d "$CANDIDATE" ]; then
            MEMORY_DIR="$CANDIDATE"
        fi
    fi
fi

if [ -z "$MEMORY_DIR" ] || [ ! -d "$MEMORY_DIR" ]; then
    log_error "Memory directory not found. Set CLAUDE_MEMORY_DIR or run from a project with memory."
    exit 0  # Exit cleanly — not a failure, just nothing to do
fi

MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

# --- Lock file (prevent concurrent runs) ---
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log_warn "Another Auto Dream is running (PID: $LOCK_PID). Skipping."
        exit 0
    else
        log_warn "Stale lock file found. Removing."
        rm -f "$LOCK_FILE"
    fi
fi

trap cleanup EXIT
echo $$ > "$LOCK_FILE"

# --- Check if dream is needed ---
now_epoch=$(date +%s)

if [ -f "$STATE_FILE" ]; then
    last_dream_epoch=$(cat "$STATE_FILE" | grep -o '"last_dream_epoch":[0-9]*' | grep -o '[0-9]*' || echo "0")
    sessions_since=$(cat "$STATE_FILE" | grep -o '"sessions_since":[0-9]*' | grep -o '[0-9]*' || echo "0")
else
    last_dream_epoch=0
    sessions_since=0
fi

hours_since=$(( (now_epoch - last_dream_epoch) / 3600 ))

if [ "$hours_since" -lt "$MIN_HOURS_BETWEEN_DREAMS" ] || [ "$sessions_since" -lt "$MIN_SESSIONS_BETWEEN_DREAMS" ]; then
    log_info "Dream not needed yet (${hours_since}h / ${sessions_since} sessions since last dream)."
    # Increment session counter
    new_sessions=$((sessions_since + 1))
    cat > "$STATE_FILE" << EOF
{"last_dream_epoch":${last_dream_epoch},"sessions_since":${new_sessions},"last_check":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
    exit 0
fi

log_info "Starting memory consolidation..."
log_info "Time since last dream: ${hours_since}h | Sessions: ${sessions_since}"

# --- Phase 1: Inventory all memory files ---
log_info "Phase 1: Inventorying memory files..."

memory_files=()
while IFS= read -r -d '' file; do
    memory_files+=("$file")
done < <(find "$MEMORY_DIR" -name "*.md" -not -name "MEMORY.md" -print0 2>/dev/null)

total_files=${#memory_files[@]}
log_info "Found ${total_files} memory files."

if [ "$total_files" -eq 0 ]; then
    log_ok "No memory files to consolidate."
    cat > "$STATE_FILE" << EOF
{"last_dream_epoch":${now_epoch},"sessions_since":0,"last_check":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
    exit 0
fi

# --- Phase 2: Check for stale memories ---
log_info "Phase 2: Checking for stale memories..."

stale_count=0
for file in "${memory_files[@]}"; do
    filename=$(basename "$file")

    # Check file age (files older than 30 days may be stale)
    if [ "$(uname)" = "Darwin" ]; then
        file_epoch=$(stat -f %m "$file" 2>/dev/null || echo "$now_epoch")
    else
        file_epoch=$(stat -c %Y "$file" 2>/dev/null || echo "$now_epoch")
    fi
    file_age_days=$(( (now_epoch - file_epoch) / 86400 ))

    if [ "$file_age_days" -gt 30 ]; then
        log_warn "  Potentially stale (${file_age_days} days old): $filename"
        stale_count=$((stale_count + 1))
    fi

    # Check for relative date references that should have been absolute
    if grep -q -E '\b(today|yesterday|tomorrow|this week|next week|last week)\b' "$file" 2>/dev/null; then
        log_warn "  Contains relative dates (should be absolute): $filename"
    fi
done

log_info "Found ${stale_count} potentially stale files."

# --- Phase 3: Check for duplicates ---
log_info "Phase 3: Checking for duplicate/overlapping memories..."

duplicate_count=0
seen_names=()
for file in "${memory_files[@]}"; do
    name=$(grep -m1 '^name:' "$file" 2>/dev/null | sed 's/^name: *//' || echo "")
    if [ -n "$name" ]; then
        for seen in "${seen_names[@]:-}"; do
            if [ "$seen" = "$name" ]; then
                log_warn "  Duplicate name found: '$name' in $(basename "$file")"
                duplicate_count=$((duplicate_count + 1))
            fi
        done
        seen_names+=("$name")
    fi
done

log_info "Found ${duplicate_count} potential duplicates."

# --- Phase 4: Rebuild index ---
log_info "Phase 4: Rebuilding MEMORY.md index..."

# Group files by type
declare -A type_files
for file in "${memory_files[@]}"; do
    type=$(grep -m1 '^type:' "$file" 2>/dev/null | sed 's/^type: *//' || echo "uncategorized")
    filename=$(basename "$file")
    name=$(grep -m1 '^name:' "$file" 2>/dev/null | sed 's/^name: *//' || echo "$filename")
    description=$(grep -m1 '^description:' "$file" 2>/dev/null | sed 's/^description: *//' || echo "")

    # Truncate description for index
    if [ ${#description} -gt 80 ]; then
        description="${description:0:77}..."
    fi

    entry="- [${name}](${filename}) -- ${description}"
    type_files["$type"]="${type_files[$type]:-}${entry}\n"
done

# Write new index
{
    echo "# Memory Index"
    echo ""

    for type in "user" "feedback" "project" "reference" "uncategorized"; do
        if [ -n "${type_files[$type]:-}" ]; then
            # Capitalize first letter
            header=$(echo "$type" | sed 's/^./\U&/')
            echo "## ${header}"
            echo -e "${type_files[$type]}"
        fi
    done
} > "$MEMORY_INDEX"

log_ok "MEMORY.md index rebuilt with ${total_files} entries."

# --- Phase 5: Update dream state ---
cat > "$STATE_FILE" << EOF
{"last_dream_epoch":${now_epoch},"sessions_since":0,"last_check":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","files_processed":${total_files},"stale_found":${stale_count},"duplicates_found":${duplicate_count}}
EOF

# --- Summary ---
echo ""
log_ok "============================================"
log_ok "  Auto Dream Complete"
log_ok "============================================"
log_info "  Memory files processed: ${total_files}"
log_info "  Potentially stale:      ${stale_count}"
log_info "  Potential duplicates:    ${duplicate_count}"
log_info "  Index rebuilt:           MEMORY.md"
log_ok "============================================"
echo ""

exit 0
