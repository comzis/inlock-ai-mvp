#!/usr/bin/env bash
# Get current DKIM public key from Mailcow (server) and update the TXT record
# for dkim._domainkey.inlock.ai via Cloudflare API.
#
# Requires: CLOUDFLARE_DNS_API_TOKEN or CLOUDFLARE_API_TOKEN (e.g. from /home/comzis/inlock/.env).
# Optional: CLOUDFLARE_ZONE_ID (default: inlock.ai zone ID).
# Optional: SERVER=user@host to fetch key from; if unset, KEY must be provided.
#
# Usage:
#   ./scripts/update_dkim_txt_cloudflare.sh
#     (fetches key from SERVER/default, updates Cloudflare)
#   KEY="v=DKIM1; k=rsa; p=..." ./scripts/update_dkim_txt_cloudflare.sh
#     (uses KEY, only updates Cloudflare)

set -euo pipefail

CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-8d7c44f4c4a25263d10b87f394bc9076}"
DKIM_RECORD_NAME="dkim._domainkey.inlock.ai"
API_BASE="https://api.cloudflare.com/client/v4"

# Load token from env or .env
if [ -z "${CLOUDFLARE_DNS_API_TOKEN:-}" ] && [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
  if [ -f /home/comzis/inlock/.env ]; then
    set -a
    # shellcheck source=/dev/null
    source /home/comzis/inlock/.env 2>/dev/null || true
    set +a
  fi
fi
CF_TOKEN="${CLOUDFLARE_DNS_API_TOKEN:-${CLOUDFLARE_API_TOKEN:-}}"
if [ -z "$CF_TOKEN" ]; then
  echo "Error: CLOUDFLARE_DNS_API_TOKEN or CLOUDFLARE_API_TOKEN not set." >&2
  exit 1
fi

# Get DKIM key: from KEY env or from server
if [ -n "${KEY:-}" ]; then
  TXT_VALUE="$KEY"
else
  SERVER="${SERVER:-comzis@100.83.222.69}"
  echo "Fetching DKIM public key from $SERVER..." >&2
  KEY_RAW="$(ssh "$SERVER" "set -a; source /home/comzis/mailcow/mailcow.conf; set +a; docker exec -i mailcowdockerized-redis-mailcow-1 redis-cli -a \"\$REDISPASS\" HGET DKIM_PUB_KEYS inlock.ai" 2>/dev/null | tr -d '\r\n')"
  if [ -z "$KEY_RAW" ]; then
    echo "Error: Could not get DKIM key from server." >&2
    exit 1
  fi
  TXT_VALUE="v=DKIM1; k=rsa; p=$KEY_RAW"
fi

# List existing TXT record(s) for dkim._domainkey
RESP="$(curl -sS -X GET "${API_BASE}/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=TXT&name=${DKIM_RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -H "Content-Type: application/json")"
RECORD_ID=""
if command -v jq >/dev/null 2>&1; then
  RECORD_ID="$(echo "$RESP" | jq -r '.result[0].id // empty')"
  SUCCESS="$(echo "$RESP" | jq -r '.success')"
else
  SUCCESS="$(echo "$RESP" | grep -o '"success":[^,]*' | head -1)"
  if echo "$RESP" | grep -q '"id"'; then
    RECORD_ID="$(echo "$RESP" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"$//')"
  fi
fi

if [ "$SUCCESS" != "true" ] && [ "$SUCCESS" != '"success":true' ]; then
  echo "Error: Cloudflare API list failed. Response: $RESP" >&2
  exit 1
fi

# Build JSON body (escape content for JSON)
if command -v jq >/dev/null 2>&1; then
  BODY="$(jq -n --arg type "TXT" --arg name "$DKIM_RECORD_NAME" --arg content "$TXT_VALUE" '{type:$type,name:$name,content:$content,ttl:3600}')"
else
  CONTENT_ESC="${TXT_VALUE//\\/\\\\}"
  CONTENT_ESC="${CONTENT_ESC//\"/\\\"}"
  BODY="{\"type\":\"TXT\",\"name\":\"${DKIM_RECORD_NAME}\",\"content\":\"${CONTENT_ESC}\",\"ttl\":3600}"
fi

if [ -n "$RECORD_ID" ]; then
  echo "Updating existing TXT record (id=$RECORD_ID)..." >&2
  RESP2="$(curl -sS -X PUT "${API_BASE}/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$BODY")"
else
  echo "Creating new TXT record..." >&2
  RESP2="$(curl -sS -X POST "${API_BASE}/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$BODY")"
fi

if command -v jq >/dev/null 2>&1; then
  SUCCESS2="$(echo "$RESP2" | jq -r '.success')"
  if [ "$SUCCESS2" != "true" ]; then
    echo "Error: Cloudflare API update/create failed. Response: $RESP2" >&2
    exit 1
  fi
  echo "Done. dkim._domainkey.inlock.ai TXT record updated via Cloudflare API." >&2
else
  if ! echo "$RESP2" | grep -q '"success":true'; then
    echo "Error: Cloudflare API update/create failed. Response: $RESP2" >&2
    exit 1
  fi
  echo "Done. dkim._domainkey.inlock.ai TXT record updated via Cloudflare API." >&2
fi

echo "Verify: dig +short TXT ${DKIM_RECORD_NAME}"
