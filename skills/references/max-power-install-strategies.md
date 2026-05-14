# max-power Install Strategies Reference

Used by `/max-power` Step 2 when ClaudeMaxPower is not yet installed. Read this on demand;
do not inline it back into the skill body.

## Decide install strategy

**Empty current directory:** install in-place automatically.

**Non-empty directory and CMP not installed:** ask the user to choose:

```
ClaudeMaxPower is not installed in this directory and the directory is not empty.
Choose an install strategy:
  1) In-place — merge ClaudeMaxPower files alongside existing code (safe: will not overwrite)
  2) Subdirectory — clone into ./claudemaxpower/ and ask you to cd into it
  3) Abort — do nothing
```

Wait for user choice before any further action.

## In-place install (option 1)

Use `rsync` with `--ignore-existing` so user files are never overwritten:

```bash
TMP="/tmp/cmp-$$"
git clone --depth 1 https://github.com/michelbr84/ClaudeMaxPower "$TMP"
rsync -a --ignore-existing --exclude='.git' "$TMP/" ./
rm -rf "$TMP"
```

If `rsync` is not available, fall back to `cp -n -R` (no-clobber):

```bash
cp -n -R "$TMP/." ./
```

If a collision would occur, list the colliding paths and skip them. Never overwrite.

## Subdirectory install (option 2)

```bash
git clone --depth 1 https://github.com/michelbr84/ClaudeMaxPower ./claudemaxpower
echo "Installed into ./claudemaxpower. cd into it and re-run /max-power."
```

## Tarball fallback (when git clone fails)

Try tarball if `git clone` errors out (no network, no git, proxy issues):

```bash
curl -fsSL https://github.com/michelbr84/ClaudeMaxPower/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=1 -C .
```

If both `git clone` and the tarball fail, stop. Ask the user to download the repository
manually and re-run `/max-power`.
