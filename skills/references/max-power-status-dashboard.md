# max-power Status Dashboard Reference

Used by `/max-power` Step 7 to render the closing status block. Fill in detected values.

## Template

```
ClaudeMaxPower status
---------------------
Version            v3.0
Mode               new-project | existing-project
Tech stack         <detected list or "none detected">
Skills loaded      assemble-team, fix-issue, gen-commit-message, generate-docs,
                   max-power, refactor-module, review-pr, superpowers-redirect
Hooks active       session-start, pre-tool-use, pre-commit-check, post-tool-use, stop
Agent teams        enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
Superpowers plugin <installed | not installed>
Environment        <.env ok | .env missing placeholders>
Next action        <recommended skill from Step 6>
```

## Field rules

- `Version` — read from `package.json` or hardcoded `v3.0` if missing.
- `Mode` — from detection in Step 1, overridden by `--mode` if provided.
- `Tech stack` — comma-separated list from manifest probes (Node, Python, Go, Rust, JVM, Ruby).
- `Skills loaded` — list the files present in `skills/*.md` (alphabetical).
- `Hooks active` — list the script names (without `.sh`) configured in `.claude/settings.json`.
- `Superpowers plugin` — best-effort detection: check whether `/superpowers:` namespace is registered, otherwise show "not installed".
- `Environment` — `.env ok` if all keys present and non-placeholder; otherwise list which are missing.
- `Next action` — the routed skill from Step 6, or `"choose from menu"` if no goal was provided.
