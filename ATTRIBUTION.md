# Attribution

ClaudeMaxPower incorporates content from third-party MIT-licensed projects. This document
provides full attribution, license terms, and a catalog of which files in this repository
derive from which upstream sources.

ClaudeMaxPower itself is MIT-licensed. Any derivative work that keeps the adapted skills
intact inherits the attribution requirement automatically.

## obra/superpowers

Full credit to Jesse Vincent and the contributors of the
[obra/superpowers](https://github.com/obra/superpowers) project. The Superpowers methodology
codifies a rigorous software-engineering workflow for Claude Code, and ClaudeMaxPower builds
on their work with gratitude.

- Upstream repository: [https://github.com/obra/superpowers](https://github.com/obra/superpowers)
- License: MIT

### MIT License (obra/superpowers)

```
MIT License

Copyright (c) Jesse Vincent and obra/superpowers contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Skills Adapted from Superpowers

The following ClaudeMaxPower skills are adapted from Superpowers. Each adapted file
includes an "Attribution" block under its H1 heading naming the upstream skill.

| ClaudeMaxPower skill      | Superpowers origin                                |
|---------------------------|---------------------------------------------------|
| `/brainstorming`          | `superpowers:brainstorming`                       |
| `/writing-plans`          | `superpowers:writing-plans`                       |
| `/subagent-dev`           | `superpowers:subagent-driven-development`         |
| `/systematic-debugging`   | `superpowers:systematic-debugging`                |
| `/finish-branch`          | `superpowers:finishing-a-development-branch`      |
| `/using-worktrees`        | `superpowers:using-git-worktrees`                 |
| `/tdd-loop`               | enhanced with methodology from `superpowers:test-driven-development` |

Adapted files remain MIT-licensed. Modifications made for ClaudeMaxPower (frontmatter style,
cross-references to ClaudeMaxPower skills and hooks, integration with Auto Dream and agent
teams) do not change the license of the underlying content.

## How We Attribute

The attribution pattern used throughout this repository:

- Each adapted skill file includes an "Attribution" block immediately under its H1 heading,
  naming the upstream skill, the upstream project, and the license.
- This `ATTRIBUTION.md` file is the single source of truth. If a skill's header attribution
  is ever unclear, this file resolves it.
- Changes to adapted skills stay MIT-licensed and carry the attribution forward. Removing
  the attribution block from a derived file is not permitted under the MIT terms.
- New skills written from scratch for ClaudeMaxPower do not carry an upstream attribution
  block, because there is no upstream to attribute.

## Our Own Contributions

ClaudeMaxPower's additions are original work by the ClaudeMaxPower maintainers and
contributors. These are not attributed to any upstream project:

- Skill format adaptation — ClaudeMaxPower's YAML frontmatter style with explicit `name`,
  `description`, `arguments`, and `allowed-tools` fields.
- `/max-power` bootstrap skill — one-command activation of the full template.
- `/assemble-team` integration with the brainstorming gate — enforces that new-project mode
  has an approved spec before the team is assembled.
- Cross-skill integration — how Superpowers-derived skills call into ClaudeMaxPower's
  existing skills (and vice versa), including the unified pipeline documented in
  `docs/superpowers-integration.md`.
- Hooks — `session-start.sh`, `pre-tool-use.sh`, `post-tool-use.sh`, `stop.sh`, and their
  configuration in `.claude/settings.json`.
- Auto Dream — the memory consolidation system and its state tracking in `.dream-state.json`.
- `.estado.md` convention — session-to-session context handoff.
- Specialized sub-agents — `code-reviewer`, `security-auditor`, `doc-writer`,
  `team-coordinator` in `.claude/agents/`.
- Workflow scripts — `batch-fix.sh`, `mass-refactor.sh`, `parallel-review.sh`,
  `dependency-graph.sh` in `workflows/`.
- Documentation — every file under `docs/` except where an upstream attribution is explicit.

## Contact

For questions about attribution, licensing, or to report an error or omission in this
document, contact the ClaudeMaxPower maintainer through the project's GitHub repository:

- ClaudeMaxPower repository: [https://github.com/michelbr84/ClaudeMaxPower](https://github.com/michelbr84/ClaudeMaxPower)
- Open an issue: [https://github.com/michelbr84/ClaudeMaxPower/issues](https://github.com/michelbr84/ClaudeMaxPower/issues)

If you believe content in this repository is insufficiently attributed or misattributed,
please open an issue and we will resolve it promptly.
