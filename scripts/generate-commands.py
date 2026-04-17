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


def main() -> int:
    if not SKILLS_DIR.is_dir():
        print(f"error: {SKILLS_DIR}/ not found. Run from project root.", file=sys.stderr)
        return 1

    CMD_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    for skill_file in sorted(SKILLS_DIR.glob("*.md")):
        text = skill_file.read_text(encoding="utf-8")
        meta = parse_frontmatter(text)
        name = meta.get("name") or skill_file.stem
        out = CMD_DIR / f"{name}.md"
        out.write_text(wrapper_text(name, meta), encoding="utf-8")
        written += 1
        print(f"  [OK] /{name} -> {out}")

    print(f"\nGenerated {written} slash-command wrappers in {CMD_DIR}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
