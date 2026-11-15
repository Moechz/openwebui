#!/bin/sh
# ===========================================================================
# Open WebUI entrypoint for a non-root container (TOS 7 requirement).
#
# Open WebUI needs a secret key to sign sessions. This wrapper generates a
# persistent one in the data folder on the first start and runs the upstream
# start script as uid 1000.
# ===========================================================================
set -e
set -u

DATA=/app/backend/data
mkdir -p "$DATA" 2>/dev/null || true

if ! ( : > "$DATA/.write-test" ) 2>/dev/null; then
  echo "openwebui: $DATA is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f "$DATA/.write-test"

KEY_FILE="$DATA/.secret-key"
if [ -s "$KEY_FILE" ]; then
  WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
else
  WEBUI_SECRET_KEY=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
  printf '%s' "$WEBUI_SECRET_KEY" > "$KEY_FILE"
  chmod 600 "$KEY_FILE" 2>/dev/null || true
fi
export WEBUI_SECRET_KEY

cd /app/backend
exec bash start.sh
