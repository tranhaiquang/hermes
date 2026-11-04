# Hermes profile sync

One-way snapshot of the portable Hermes profile content from this machine,
pushed to this repo on a daily schedule.

**Synced:**
- `skills/` — all skills (incl. custom)
- `memories/` — MEMORY.md, USER.md
- `plugins/`
- `SOUL.md`
- `config.yaml`

**Not synced (machine-local by design):** `state.db`, `sessions/`, `auth.json`,
`.env`, `cron/` runtime files, logs, caches.

Restore on another machine by cloning this repo and copying the folders into
that machine's `AppData\Local\hermes\` (or `~/.hermes/`).

Sync script: `%HERMES_HOME%\scripts\profile_sync.py`
