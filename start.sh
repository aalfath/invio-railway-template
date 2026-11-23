#!/usr/bin/env bash
# Runs Invio's backend (Deno, loopback port) and frontend (Bun, $PORT) without supervisord.
# If either process stops, the other is stopped too and the container exits non-zero,
# so Railway's ON_FAILURE restart policy brings it back.
set -uo pipefail

export DATABASE_PATH="${DATABASE_PATH:-/app/data/invio.db}"
export BACKEND_PORT="${BACKEND_PORT:-3000}"
FRONTEND_PORT="${PORT:-8000}"
mkdir -p "$(dirname "$DATABASE_PATH")"

if [ -z "${ADMIN_PASS:-}" ] || [ -z "${JWT_SECRET:-}" ]; then
  echo "invio-start: ADMIN_PASS and JWT_SECRET must be set" >&2
  exit 1
fi

# Keep each runtime small on Railway's 0.5 GB Free plan.
export DENO_V8_FLAGS="${DENO_V8_FLAGS:---max-old-space-size=192}"

cd /app/backend
env -u PORT deno run --cached-only --allow-read --allow-write --allow-net --allow-env --allow-run src/app.ts &
BPID=$!

# Wait for the backend (database init, admin seeding) before starting the frontend.
for _ in $(seq 1 240); do
  if curl -fsS -o /dev/null "http://127.0.0.1:${BACKEND_PORT}/health"; then break; fi
  if ! kill -0 "$BPID" 2>/dev/null; then
    wait "$BPID"; echo "invio-start: backend exited during start-up (code $?)" >&2; exit 1
  fi
  sleep 0.5
done

cd /app/frontend
PORT="$FRONTEND_PORT" HOST="${HOST:-0.0.0.0}" \
BACKEND_URL="http://127.0.0.1:${BACKEND_PORT}" \
BODY_SIZE_LIMIT="${BODY_SIZE_LIMIT:-10M}" \
PROTOCOL_HEADER="${PROTOCOL_HEADER:-x-forwarded-proto}" \
NODE_ENV=production \
  bun --no-install build/index.js &
FPID=$!

stopping=0
trap 'stopping=1; kill -TERM "$BPID" "$FPID" 2>/dev/null' TERM INT

wait -n "$BPID" "$FPID"
code=$?
kill -TERM "$BPID" "$FPID" 2>/dev/null
wait 2>/dev/null
if [ "$stopping" = 1 ]; then exit 0; fi
echo "invio-start: a process stopped unexpectedly (code $code); exiting so Railway restarts the service" >&2
exit 1
