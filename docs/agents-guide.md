# Agents Guide

Sub-agents are specialized Claude sessions with persistent memory. They improve over time and bring focused expertise to specific tasks.

## How Agents Work

An agent is a `.md` file in `.claude/agents/` that defines:
- **Role** — what the agent specializes in
- **Memory** — what it remembers across sessions (`project` or `user`)
- **Allowed tools** — what it can do (restricted for safety)
- **Output format** — how it structures its responses

Claude Code can invoke an agent as a sub-session — it runs independently with its own context.

## Memory Types

| Memory | Scope | What Gets Remembered |
|--------|-------|---------------------|
| `project` | Per repository | Code patterns, known issues, architecture decisions |
| `user` | Per user account | Writing style preferences, feedback, working patterns |
| none | Session only | Nothing persists |

**Project memory** is ideal for code reviewers and security auditors — they build up knowledge of your specific codebase.

**User memory** is ideal for doc writers — they learn your style once and maintain it.

## Available Agents

### code-reviewer

**Memory:** project
**Tools:** Read, Glob, Grep, Bash (read-only)

A strict senior engineer who reviews code for correctness, security, and maintainability.

**Checklist:**
- Logic errors and edge cases
- Missing error handling
- OWASP security basics
- Test coverage quality
- Project convention compliance

**Output format:**
```
## Code Review
**Verdict**: APPROVED | CHANGES REQUESTED | NEEDS DISCUSSION
### ✅ What's Good
### ❌ Blocking Issues
### ⚠ Suggestions
### 🔒 Security Notes
### 🧪 Test Assessment
```

**Example invocation:**
```
Review this diff using the code-reviewer agent:
[paste diff or point to PR]
```

---

### security-auditor

**Memory:** project
**Tools:** Read, Glob, Grep, Bash (read-only)

Security engineer performing OWASP Top 10 scans and credential audits.

**Checks:**
- A01 Broken Access Control
- A02 Cryptographic Failures (hardcoded secrets, weak hashing)
- A03 Injection (SQL, command, XSS)
- A04 Insecure Design
- A05 Security Misconfiguration
- A06 Vulnerable Components (`pip-audit`, `npm audit`)
- A07-A10 Additional categories

**Output format:**
```
## Security Audit Report
Risk Level: CRITICAL | HIGH | MEDIUM | LOW | CLEAN
### CRITICAL Issues (table: ID, File, Line, Issue, Recommendation)
### HIGH Issues
### MEDIUM Issues
### Dependency Vulnerabilities
### OWASP Coverage Summary
```

**Example invocation:**
```
Run a security audit on the examples/todo-app directory using the security-auditor agent.
```

---

### doc-writer

**Memory:** user
**Tools:** Read, Glob, Grep, Edit, Write

Technical writer who generates and maintains documentation.

**Produces:**
- README files (with Quick Start, Features, Usage, Contributing sections)
- API reference docs (from docstrings and function signatures)
- Tutorial guides (step-by-step, always with working commands)
- Inline docstrings (Python Google style, JSDoc)

**Writing style:**
- Active voice
- Concrete examples over abstract descriptions
- No "simply", "just", "easily"
- Learns your preferences across sessions

**Example invocation:**
```
Generate API documentation for all public functions in src/todo.py using the doc-writer agent.
```

---

## Writing Your Own Agent

Create `.claude/agents/my-agent.md`:

```markdown
---
name: my-agent
description: What this agent does
model: claude-sonnet-4-6
memory: project
allowed-tools:
  - Read
  - Grep
---

# Agent: my-agent

## Your Role
[Define the agent's persona and specialty]

## Checklist / Process
[What the agent checks or does]

## Output Format
[How the agent structures its response]
```

**Tips:**
- Keep `allowed-tools` minimal — agents rarely need Write or Bash
- Define a clear, narrow role — generalist agents are less useful
- Specify output format exactly — structured output is easier to act on
- Use `memory: project` for anything codebase-specific
- Use `memory: user` for style/preference adaptation
