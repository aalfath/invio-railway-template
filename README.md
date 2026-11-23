[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/invio-1?utm_medium=integration&utm_source=button&utm_campaign=invio)

# Invio on Railway

One-click [Invio](https://github.com/kittendevv/Invio) for [Railway](https://railway.com): simple self-hosted invoicing with clients, products, invoices, PDF and e-invoice export (Factur-X / ZUGFeRD, UBL, FatturaPA), shareable invoice links and payment tracking.

- **App:** Invio **v2.5.0**, official image `ghcr.io/kittendevv/invio:v2.5.0`, pinned by digest `sha256:8e2222c699daaee1e996c0de54cb94a53ad494a295b72bd693ed9fdcd1a5d7b6`.
- **One service** (`Invio`), built from this repo's `Dockerfile`. The Deno backend listens on `127.0.0.1:3000` inside the container and the SvelteKit frontend serves the public URL on `$PORT` (8000).
- **Data:** a Railway volume at `/app/data` holds the SQLite database (`invio.db`), uploaded logos and invoice templates. It survives redeploys and restarts.
- **Health check:** `/login` (answers without a login once the backend is up).

## Variables

| Variable | Default | What it does |
|---|---|---|
| `ADMIN_USER` | `admin` | Username of the admin account created on first boot. |
| `ADMIN_PASS` | generated (`${{secret(24)}}`) | Password of that admin account. Read it in the service's **Variables** tab. |
| `JWT_SECRET` | generated (`${{secret(48)}}`) | Signs login sessions. Changing it logs everyone out. |
| `PORT` | `8000` | Port the web UI listens on (the Railway domain points here). |

There's nothing to fill in at deploy time. The admin account is created from `ADMIN_USER`/`ADMIN_PASS` on the first boot only; after that, change the password in **Settings** in the app, not in the variable.

Optional, add them yourself if you need them (see upstream's [`.env.example`](https://github.com/kittendevv/Invio/blob/v2.5.0/.env.example)):

- **Email:** `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `EMAIL_FROM_ADDRESS`, `EMAIL_FROM_NAME` turn on "Send via Email" for invoices.
- **SSO (OIDC):** `OIDC_ENABLED=true`, `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_REDIRECT_URI=https://YOUR-DOMAIN/auth/callback`.
- **Custom domain:** works as is (form posts are checked against the request's host). Set `ORIGIN=https://YOUR-DOMAIN` only if you want to pin it.

## What this wrapper changes

Upstream's image runs both processes under supervisord. This repo keeps the official image and adds only `start.sh` and a few defaults:

- `DATABASE_PATH=/app/data/invio.db`, so the database lands on the volume.
- The backend's Deno modules are cached into the image at build time (`DENO_DIR=/opt/deno-cache`), so a start never downloads code and works even when deno.land is slow.
- `start.sh` starts the backend on loopback, waits for its `/health`, then starts the frontend on `$PORT`. If either process stops unexpectedly, the container exits non-zero, so Railway's restart policy brings it back (supervisord would have kept a half-dead container running).
- The Deno heap is capped at 192 MB (`DENO_V8_FLAGS`), so the app fits Railway's 0.5 GB Free plan. Measured on Railway at 0.5 GB / 1 vCPU: see `CHANGELOG.md`.

Login rate limiting is upstream's: 5 failed logins in 15 minutes block further attempts for that window.

## Updates

Railway shows deployers of this template an "update available" notice when this repo's `main` branch changes. Each change is listed in [`CHANGELOG.md`](CHANGELOG.md), breaking changes first. Invio runs its own database migrations at start, so applying an update keeps your data. Back up the volume before a major version.

## Licence

Invio is released into the public domain under the [Unlicense](https://github.com/kittendevv/Invio/blob/v2.5.0/LICENSE). The files in this repo are under the same terms.
