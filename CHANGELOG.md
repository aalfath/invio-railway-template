# Changelog

## 2.5.0-railway.1 (2026-11-23)

First release of the Railway template.

- Invio v2.5.0 (`ghcr.io/kittendevv/invio:v2.5.0@sha256:8e2222c699daaee1e996c0de54cb94a53ad494a295b72bd693ed9fdcd1a5d7b6`).
- One service with a volume at `/app/data` (SQLite database, logos, invoice templates).
- Generated admin password and JWT secret; no prompts at deploy time.
- `start.sh` replaces supervisord: backend on loopback, frontend on `$PORT`, non-zero exit if either process stops.
- Deno modules cached at build time; Deno heap capped at 192 MB for Railway's 0.5 GB plan.
