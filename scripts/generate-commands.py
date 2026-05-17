#!/usr/bin/env python3
"""Generate Claude Code slash-command wrappers from skills/*.md.

Claude Code auto-discovers slash commands from .claude/commands/<name>.md.
ClaudeMaxPower documents skills in skills/*.md (source of truth). This
script emits one thin wrapper per skill so /name shows up in the / menu
and, when invoked, tells Claude to follow the canonical skill file.

Run from the project root:
    python3 scripts/generate-commands.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

SKILLS_DIR = Path("skills")
CMD_DIR = Path(".claude/commands")

# Signature of a wrapper this script previously generated. Used by the
# stale-wrapper sweep to distinguish auto-generated wrappers from any
# hand-written commands a user may have added to .claude/commands/.
WRAPPER_SIGNATURE = "Read `skills/"
WRAPPER_SIGNATURE_TAIL = "in this repository and execute its workflow verbatim."

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
NAME_RE = re.compile(r"^name:\s*(\S+)\s*$", re.MULTILINE)
DESC_RE = re.compile(r"^description:\s*(.+?)\s*$", re.MULTILINE)
TOOLS_BLOCK_RE = re.compile(r"^allowed-tools:\s*\n((?:\s*-\s*\S+\s*\n?)+)", re.MULTILINE)
ARGS_BLOCK_RE = re.compile(r"^arguments:\s*\n((?:\s*-\s*name:.*?\n(?:\s{2,}.*\n)*)+)", re.MULTILINE)
ARG_ITEM_RE = re.compile(
    r"-\s*name:\s*(\S+)\s*\n"
    r"(?:\s+description:\s*.+\n)?"
    r"(?:\s+required:\s*(true|false)\s*\n)?",
    re.MULTILINE,
)


def parse_frontmatter(text: str) -> dict:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    fm = m.group(1)
    data = {}
    if (nm := NAME_RE.search(fm)):
        data["name"] = nm.group(1)
    if (dm := DESC_RE.search(fm)):
        data["description"] = dm.group(1).strip().strip('"').strip("'")
    if (tm := TOOLS_BLOCK_RE.search(fm)):
        data["tools"] = [
            line.strip("- \n") for line in tm.group(1).splitlines() if line.strip()
        ]
    if (am := ARGS_BLOCK_RE.search(fm)):
        data["arguments"] = [
            {"name": n, "required": (req == "true")}
            for n, req in ARG_ITEM_RE.findall(am.group(1))
        ]
    return data


def build_argument_hint(args: list[dict]) -> str:
    parts = []
    for a in args:
        token = f"--{a['name']} <value>"
        parts.append(token if a.get("required") else f"[{token}]")
    return " ".join(parts)


def wrapper_text(skill_name: str, meta: dict) -> str:
    desc = meta.get("description", f"Run the {skill_name} workflow.")
    hint = build_argument_hint(meta.get("arguments", []))
    tools = meta.get("tools", [])

    lines = ["---", f"description: {desc}"]
    if hint:
        lines.append(f"argument-hint: {hint}")
    if tools:
        lines.append(f"allowed-tools: {', '.join(tools)}")
    lines.append("---")
    lines.append("")
    lines.append(
        f"Read `skills/{skill_name}.md` in this repository and execute its "
        f"workflow verbatim. Parse any arguments the user passed below and "
        f"bind them to the skill's declared arguments before running."
    )
    lines.append("")
    lines.append("User arguments: $ARGUMENTS")
    lines.append("")
    return "\n".join(lines)


def is_generated_wrapper(path: Path) -> tuple[bool, str | None]:
    """Return (is_wrapper, referenced_skill_name) for files this script emits.

    Identifies wrappers by the literal body line the generator writes. Hand-written
    commands without that signature are left untouched.
    """
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return (False, None)
    if WRAPPER_SIGNATURE not in text or WRAPPER_SIGNATURE_TAIL not in text:
        return (False, None)
    m = re.search(r"Read `skills/([A-Za-z0-9_.-]+)\.md`", text)
    return (True, m.group(1) if m else None)


def sweep_stale_wrappers(current_skill_names: set[str]) -> int:
    """Remove wrappers whose source skill no longer exists.

    Only deletes files this script previously generated (signature match).
    Returns the count removed.
    """
    if not CMD_DIR.is_dir():
        return 0
    removed = 0
    for cmd_file in sorted(CMD_DIR.glob("*.md")):
        is_wrapper, referenced = is_generated_wrapper(cmd_file)
        if not is_wrapper:
            continue
        if referenced and referenced not in current_skill_names:
            cmd_file.unlink()
            removed += 1
            print(f"  [RM] /{referenced} -> {cmd_file} (source skill removed)")
    return removed


def main() -> int:
    if not SKILLS_DIR.is_dir():
        print(f"error: {SKILLS_DIR}/ not found. Run from project root.", file=sys.stderr)
        return 1

    CMD_DIR.mkdir(parents=True, exist_ok=True)

    skill_files = sorted(SKILLS_DIR.glob("*.md"))
    skill_metas: list[tuple[str, dict]] = []
    for skill_file in skill_files:
        text = skill_file.read_text(encoding="utf-8")
        meta = parse_frontmatter(text)
        name = meta.get("name") or skill_file.stem
        skill_metas.append((name, meta))

    current_names = {name for name, _ in skill_metas}
    removed = sweep_stale_wrappers(current_names)

    written = 0
    for name, meta in skill_metas:
        out = CMD_DIR / f"{name}.md"
        # newline="\n" prevents Python from translating \n to \r\n on Windows.
        # The repo's .gitattributes enforces LF for *.md, so without this the
        # working tree on Windows looks "modified" right after every setup.sh.
        out.write_text(wrapper_text(name, meta), encoding="utf-8", newline="\n")
        written += 1
        print(f"  [OK] /{name} -> {out}")

    print(f"\nGenerated {written} slash-command wrappers in {CMD_DIR}/")
    if removed:
        print(f"Removed {removed} stale wrapper(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
