#!/usr/bin/env bash
# Get current DKIM public key from Mailcow (redis) on the server.
# Run from repo root or with SERVER=user@host. Output: host name and TXT value for DNS.

set -euo pipefail

SERVER="${SERVER:-comzis@100.83.222.69}"

ssh "$SERVER" <<'SSH'
set -a; source /home/comzis/mailcow/mailcow.conf; set +a
KEY=$(docker exec -i mailcowdockerized-redis-mailcow-1 redis-cli -a "$REDISPASS" HGET DKIM_PUB_KEYS inlock.ai | tr -d '\r\n')
echo "Publish this TXT record:"
echo "Host/Name: dkim._domainkey.inlock.ai"
echo "Value: v=DKIM1; k=rsa; p=$KEY"
SSH
