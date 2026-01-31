#!/bin/bash
# Add or remove an IP allow rule in Cloudflare (zone-level) via API.
# Use this so a specific IP (e.g. your MacBook public IP) can reach inlock.ai
# when Cloudflare is blocking or challenging it.
#
# Prerequisites:
#   - CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID in .env (or exported).
#   - Token needs "Zone - Firewall - Edit" (or "Firewall Access Rules Write") permission.
#
# Usage:
#   ./scripts/cloudflare-allow-ip.sh [IP]              # Add allow rule for IP (default: 31.10.147.220)
#   ./scripts/cloudflare-allow-ip.sh --list            # List current zone IP access rules
#   ./scripts/cloudflare-allow-ip.sh --delete [IP]    # Delete allow rule for IP
#
# Examples:
#   ./scripts/cloudflare-allow-ip.sh                   # Allow 31.10.147.220
#   ./scripts/cloudflare-allow-ip.sh 1.2.3.4           # Allow 1.2.3.4
#   ./scripts/cloudflare-allow-ip.sh --list
#   ./scripts/cloudflare-allow-ip.sh --delete 31.10.147.220

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env from repo root or current directory
# Use || true so grep missing a line doesn't trigger set -e and exit the script
load_env() {
  local f="$1"
  [ ! -f "$f" ] && return
  # Token: CLOUDFLARE_API_TOKEN or CLOUDFLARE_DNS_API_TOKEN
  if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    CLOUDFLARE_API_TOKEN=$(grep -E "^CLOUDFLARE_API_TOKEN=" "$f" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | head -1) || true
  fi
  if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    CLOUDFLARE_API_TOKEN=$(grep -E "^CLOUDFLARE_DNS_API_TOKEN=" "$f" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | head -1) || true
  fi
  if [ -z "${CLOUDFLARE_ZONE_ID:-}" ]; then
    CLOUDFLARE_ZONE_ID=$(grep -E "^CLOUDFLARE_ZONE_ID=" "$f" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | head -1) || true
  fi
  if [ -z "${DOMAIN:-}" ]; then
    DOMAIN=$(grep -E "^DOMAIN=" "$f" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'" | head -1) || true
  fi
  export CLOUDFLARE_API_TOKEN CLOUDFLARE_ZONE_ID DOMAIN CLOUDFLARE_FIREWALL_API_TOKEN
}

load_env "$REPO_ROOT/.env"
load_env ".env"

cd "$REPO_ROOT"

API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
# Firewall API: use token with Zone - Firewall - Edit (or same as API_TOKEN)
FIREWALL_TOKEN="${CLOUDFLARE_FIREWALL_API_TOKEN:-$API_TOKEN}"
ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"
DOMAIN="${DOMAIN:-inlock.ai}"

# If zone ID not in .env, fetch it from Cloudflare API by domain name
if [ -z "$ZONE_ID" ] && [ -n "$API_TOKEN" ]; then
  RES=$(curl -sS -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
    -H "Authorization: Bearer ${API_TOKEN}" -H "Content-Type: application/json" 2>/dev/null) || true
  if echo "$RES" | grep -qE '"success"\s*:\s*true'; then
    ZONE_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('result',[]); print(r[0]['id'] if r else '')" 2>/dev/null) || true
  fi
fi
BASE_URL="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/firewall/access_rules/rules"

usage() {
  echo "Usage: $0 [IP]           # Add allow rule (default IP: 31.10.147.220)"
  echo "       $0 --list        # List zone IP access rules"
  echo "       $0 --delete [IP] # Delete allow rule for IP"
  echo ""
  echo "Requires: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID in .env or environment."
  echo "Token permission: Zone - Firewall - Edit (Firewall Access Rules Write)."
}

cf_request() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  local token="${4:-$FIREWALL_TOKEN}"
  if [ -n "$data" ]; then
    curl -sS -X "$method" "$url" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -sS -X "$method" "$url" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json"
  fi
}

list_rules() {
  local res
  res=$(cf_request GET "$BASE_URL")
  if ! echo "$res" | grep -q '"success":true'; then
    echo "API error:" >&2
    echo "$res" | head -20 >&2
    return 1
  fi
  echo "$res" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
  cfg = r.get('configuration', {})
  print(r.get('mode', ''), cfg.get('value', ''), '-', r.get('notes', '')[:60], '- id:', r.get('id', ''))
" 2>/dev/null || echo "$res"
}

delete_rule_for_ip() {
  local ip="$1"
  local res list id
  res=$(cf_request GET "$BASE_URL")
  if ! echo "$res" | grep -q '"success":true'; then
    echo "API error listing rules:" >&2
    echo "$res" | head -20 >&2
    return 1
  fi
  id=$(echo "$res" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('result', []):
  if r.get('configuration', {}).get('value') == '$ip' and r.get('mode') == 'whitelist':
    print(r.get('id', ''))
    break
" 2>/dev/null)
  if [ -z "$id" ]; then
    echo "No whitelist rule found for IP: $ip"
    return 0
  fi
  res=$(cf_request DELETE "${BASE_URL}/${id}")
  if echo "$res" | grep -q '"success":true'; then
    echo "Deleted rule for $ip (id: $id)"
  else
    echo "API error deleting rule:" >&2
    echo "$res" >&2
    return 1
  fi
}

add_rule() {
  local ip="$1"
  local notes="Allow my IP ($ip) - inlock.ai"
  local data
  data=$(printf '{"mode":"whitelist","configuration":{"target":"ip","value":"%s"},"notes":"%s"}' "$ip" "$notes")
  local res
  echo "Calling Cloudflare API to add allow rule for $ip ..."
  res=$(cf_request POST "$BASE_URL" "$data")
  # Cloudflare may return "success": true with a space
  if echo "$res" | grep -qE '"success"\s*:\s*true'; then
    echo "OK: Added allow rule for $ip"
    echo "$res" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('result',{}); print('Rule id:', r.get('id','')); print('Mode:', r.get('mode',''))" 2>/dev/null || true
  else
    echo "API error (response below):"
    echo "$res"
    if echo "$res" | grep -qi "Authentication error"; then
      echo ""
      echo "Your token can list zones but cannot create firewall rules. Do one of:"
      echo "  1. In Cloudflare: My Profile → API Tokens → Edit your token → add permission: Zone - Firewall - Edit"
      echo "  2. Or create a new token with Zone - Firewall - Edit and add to .env:"
      echo "     CLOUDFLARE_FIREWALL_API_TOKEN=your-new-token"
    fi
    return 1
  fi
}

# --- main ---
if [ -z "$API_TOKEN" ]; then
  echo "Missing CLOUDFLARE_API_TOKEN (or CLOUDFLARE_DNS_API_TOKEN) in .env or environment." >&2
  echo "Add to $REPO_ROOT/.env" >&2
  usage >&2
  exit 1
fi
if [ -z "$ZONE_ID" ]; then
  echo "Could not get Zone ID (tried CLOUDFLARE_ZONE_ID in .env and API lookup for domain ${DOMAIN})." >&2
  echo "Add to $REPO_ROOT/.env:  CLOUDFLARE_ZONE_ID=your-zone-id   # Dashboard → inlock.ai → Overview → Zone ID" >&2
  usage >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  list_rules
  exit 0
fi

if [ "${1:-}" = "--delete" ]; then
  IP="${2:-31.10.147.220}"
  if [ -z "$IP" ]; then
    usage >&2
    exit 1
  fi
  delete_rule_for_ip "$IP"
  exit 0
fi

IP="${1:-31.10.147.220}"
echo "Target IP: $IP"
echo "Zone ID:   ${ZONE_ID:0:20}..."
add_rule "$IP"
echo "Done."
