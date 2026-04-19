# Troubleshooting

Common issues and how to fix them.

---

## Hooks Not Firing

**Symptom:** Session start hook doesn't run, or tests aren't auto-running after edits.

**Check 1: Settings file path**
```bash
cat .claude/settings.json
```
Verify the `hooks` key exists and the commands are correct.

**Check 2: Script is executable**
```bash
ls -la .claude/hooks/
# Should show -rwxr-xr-x (executable bit set)
chmod +x .claude/hooks/*.sh
```

**Check 3: Script exits 0**
Run the hook manually:
```bash
bash .claude/hooks/session-start.sh
echo "Exit code: $?"
```
Non-zero exit code may cause Claude Code to suppress output.

**Check 4: Working directory**
Hooks run from the project root. Verify `.claude/settings.json` is in the project root (same directory where you run `claude`).

---

## Skill Not Found

**Symptom:** `/fix-issue` says skill not found.

**Check:** Skills must be in the `skills/` directory relative to where you opened Claude:
```bash
ls skills/fix-issue.md
```

If the file exists but Claude doesn't find it, ensure you opened `claude` from the project root.

---

## GitHub CLI Not Authenticated

**Symptom:** `gh` commands fail with "not logged in" or 401 error.

**Fix:**
```bash
gh auth login
# Follow the interactive prompts
gh auth status  # Verify
```

---

## GITHUB_TOKEN Not Set

**Symptom:** Skills that use `gh` fail, or `.env` warning in session-start hook.

**Fix:**
1. Check `.env` exists: `ls -la .env`
2. If not: `cp .env.example .env`
3. Edit `.env` and add your token
4. Token needs scopes: `repo`, `read:org`
5. Create at: [github.com/settings/tokens](https://github.com/settings/tokens)

---

## Tests Not Running After File Edit

**Symptom:** `post-tool-use.sh` runs but says "no tests/ directory found."

**This is expected if:**
- You edited a file in `docs/`, `skills/`, `.claude/` — not source code
- The project doesn't have a `tests/` directory yet

**If you expect tests to run:**
- The `tests/` directory must be within 3 levels of the edited file
- For `src/foo.py`, the hook looks for `src/tests/`, `tests/`, `../tests/`
- Check the hook output for exactly what path it searched

---

## Batch Script Fails

**Symptom:** `batch-fix.sh` or `mass-refactor.sh` exits with an error.

**Check 1: jq installed**
```bash
jq --version
```
Install: `brew install jq` or `apt install jq`

**Check 2: claude CLI available in PATH**
```bash
which claude
claude --version
```

**Check 3: Run with a single item first**
```bash
./workflows/batch-fix.sh owner/repo 1
```
Test with one issue before running a batch.

**Check 4: Check batch-results.json**
```bash
cat batch-results.json | jq '.[].status'
```

---

## MCP Server Not Connecting

**Symptom:** `/mcp` shows no servers, or GitHub/Sentry tools aren't available.

**Check 1: settings.json has mcpServers**
```bash
cat .claude/settings.json | jq '.mcpServers'
```

**Check 2: npx can reach the package**
```bash
npx -y @modelcontextprotocol/server-github --help 2>&1 | head -5
```

**Check 3: GitHub token is valid**
```bash
source .env
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

**Check 4: Sentry remote MCP — re-run OAuth**

The Sentry default integration uses OAuth, not a token. If `/mcp` shows `sentry`
as failed or never authenticated, re-run the auth flow:
```
/mcp
```
Click the auth link next to `sentry`. If the link doesn't appear, try removing
and re-adding the server:
```bash
claude mcp remove sentry
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```
You can revoke previously-granted access at
[sentry.io/settings/account/api/authorized-applications/](https://sentry.io/settings/account/api/authorized-applications/).

---

## Worktree Cleanup After Crash

**Symptom:** `git worktree add` fails saying the path already exists.

**Fix:**
```bash
# List all worktrees
git worktree list

# Remove stale ones
git worktree remove --force /tmp/claudemaxpower-writer-*
git worktree prune

# Delete leftover temp branches
git branch | grep "writer\|reviewer" | xargs git branch -D
```

---

## Python Import Errors in Examples

**Symptom:** `ModuleNotFoundError` when running tests in `examples/todo-app/`.

**Fix:**
```bash
cd examples/todo-app
pip install -r requirements.txt
python -m pytest tests/ -v
```

The tests add `src/` to `sys.path` automatically, so you don't need to install the package.

---

## Getting More Help

- Run `bash scripts/verify.sh` — catches most common issues
- Check `.claude/audit.log` — every bash command Claude ran
- Check `.estado.md` — summary of what previous sessions did
- Open an issue: [github.com/your-username/ClaudeMaxPower/issues](https://github.com/your-username/ClaudeMaxPower/issues)
