# Optional Local Postgres for Development

> **Is this required?** No. ClaudeMaxPower does **not** require Postgres. This guide
> documents an *optional* local-development helper for example apps and experiments
> that need a real database. Skip this entire page unless you specifically need a
> local Postgres.

## What this provides

- Postgres 16 in a Docker container, scoped to your machine only.
- A named volume so data survives `down`/`up`.
- A safety-first defaults profile: loopback-only port, no hardcoded password.
- Documentation for setup, common operations, and password rotation.

## Prerequisites

- Docker Desktop or Docker Engine + the Docker Compose plugin (`docker compose`, not
  the legacy `docker-compose`).

Verify with:

```bash
docker --version
docker compose version
```

## Setup

1. **Copy the env template if you have not already:**

   ```bash
   cp .env.example .env
   ```

2. **Set a strong local-only password.** Edit `.env` and replace the placeholder
   `POSTGRES_PASSWORD=change-me-local-only` with a value of your choosing.

   - Use a generator (`openssl rand -hex 24` is fine).
   - This password is for your laptop only. It is never committed because `.env` is
     gitignored.
   - Update `DB_URL` in the same `.env` so the password matches.

3. **Start Postgres:**

   ```bash
   docker compose -f docker-compose.postgres.yml up -d
   ```

   The first run pulls the `postgres:16` image, creates the `claudemaxpower_pgdata`
   named volume, and exposes the database on `127.0.0.1:5432`.

4. **Confirm it is up:**

   ```bash
   docker compose -f docker-compose.postgres.yml ps
   docker compose -f docker-compose.postgres.yml exec postgres pg_isready -U postgres
   ```

## Common commands

| Action | Command |
|---|---|
| Start (background) | `docker compose -f docker-compose.postgres.yml up -d` |
| Stop (keep data) | `docker compose -f docker-compose.postgres.yml down` |
| Stop and **delete** data | `docker compose -f docker-compose.postgres.yml down -v` |
| Tail logs | `docker compose -f docker-compose.postgres.yml logs -f postgres` |
| Open psql shell | `docker compose -f docker-compose.postgres.yml exec postgres psql -U postgres -d claudemaxpower` |
| Status | `docker compose -f docker-compose.postgres.yml ps` |

## Connecting from an app

The example connection string follows the standard libpq format:

```
postgresql://postgres:<your-local-password>@127.0.0.1:5432/claudemaxpower
```

A psql one-liner from the host (requires `psql` installed locally):

```bash
psql "postgresql://postgres:$POSTGRES_PASSWORD@127.0.0.1:5432/claudemaxpower"
```

## Rotating the password

Do this immediately if your local password ever appeared in a screenshot, chat
transcript, issue, PR, commit, log file, or terminal recording — even if it never
reached the public repo.

1. Stop the container (data preserved):

   ```bash
   docker compose -f docker-compose.postgres.yml down
   ```

2. Wipe the volume so the new password takes effect from a fresh data directory:

   ```bash
   docker compose -f docker-compose.postgres.yml down -v
   ```

   (Postgres only sets the password from `POSTGRES_PASSWORD` when initialising a new
   data directory. Without `-v`, the old password persists.)

3. Update the password in `.env`. Update `DB_URL` to match.

4. Start again:

   ```bash
   docker compose -f docker-compose.postgres.yml up -d
   ```

5. Audit any place the old value might have leaked: shell history (`history | grep
   postgresql`), terminal scrollback, screenshots, chat tools, agent memory stores.
   Where you cannot delete the trace, treat the value as compromised forever and
   never reuse it.

## Security rules

- **Loopback only.** The compose file binds `127.0.0.1:5432:5432`. Never change this
  to `5432:5432` or `0.0.0.0:5432:5432` — that would expose Postgres to your LAN
  (and on some hosts, the open Internet).
- **No default password.** `POSTGRES_PASSWORD` is read from `.env` with the
  `${POSTGRES_PASSWORD:?...}` syntax, so the container refuses to start if the
  variable is missing. There is no hardcoded fallback to leak.
- **Never commit `.env`.** It is in `.gitignore` (lines 1-4). Verify with
  `git check-ignore -v .env` before committing if you are ever uncertain.
- **Never paste real DB credentials anywhere public.** That includes issues, PRs,
  commit messages, doc files, screenshots, screen recordings, chat tools, and AI
  agent prompts. If a credential was pasted, treat it as compromised and rotate.
- **Use a unique password.** Even though the port is loopback-only, do not reuse a
  password from any other system. Local-only does not mean impact-free.

## Removing it entirely

If you decide you do not want this optional helper:

```bash
docker compose -f docker-compose.postgres.yml down -v
rm docker-compose.postgres.yml docs/dev-postgres.md
# remove POSTGRES_PASSWORD and DB_URL lines from .env and .env.example
```

ClaudeMaxPower will continue to function — no skill, hook, or example currently
depends on Postgres.
