#!/usr/bin/env bash
set -euo pipefail

# Audits age/expiry of secrets and certs.
# Exit non-zero if any secret is missing or overdue.

SECRETS_DIR="${SECRETS_DIR:-/home/comzis/apps/secrets-real}"
ENV_FILE="${ENV_FILE:-/home/comzis/inlock-infra/.env}"
APP_ENV_FILE="${APP_ENV_FILE:-/opt/inlock-ai-secure-mvp/.env.production}"

now_epoch="$(date +%s)"
status=0

check_age() {
  local path="$1" max_days="$2" label="$3"
  if [[ -f "$path" ]]; then
    local mtime epoch_age days
    mtime="$(stat -c %Y "$path")"
    epoch_age=$(( now_epoch - mtime ))
    days=$(( epoch_age / 86400 ))
    if (( days > max_days )); then
      echo "❌ ${label}: ${days}d old (> ${max_days}d) :: ${path}"
      status=1
    else
      echo "✅ ${label}: ${days}d old (<= ${max_days}d) :: ${path}"
    fi
  else
    echo "⚠️  ${label}: missing :: ${path}"
    status=1
  fi
}

check_cert_expiry() {
  local cert="$1" label="$2" min_days="$3"
  if [[ -f "$cert" ]]; then
    local enddate expiry_epoch days_left
    enddate="$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2 || true)"
    if [[ -z "$enddate" ]]; then
      echo "⚠️  ${label}: cannot read expiry :: ${cert}"
      status=1
      return
    fi
    expiry_epoch="$(date -d "$enddate" +%s)"
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
    if (( days_left < min_days )); then
      echo "❌ ${label}: ${days_left}d remaining (< ${min_days}d) :: ${cert}"
      status=1
    else
      echo "✅ ${label}: ${days_left}d remaining (>= ${min_days}d) :: ${cert}"
    fi
  else
    echo "⚠️  ${label}: missing :: ${cert}"
    status=1
  fi
}

echo "=== Secret Age Audit ==="
echo "SECRETS_DIR=${SECRETS_DIR}"
echo ""

# File-based secrets
check_age "${SECRETS_DIR}/traefik-dashboard-users.htpasswd" 90 "Traefik basic auth"
check_age "${SECRETS_DIR}/portainer-admin-password" 90 "Portainer admin password"
check_age "${SECRETS_DIR}/grafana-admin-password" 90 "Grafana admin password"
check_age "${SECRETS_DIR}/n8n-db-password" 90 "n8n DB password"
check_age "${SECRETS_DIR}/n8n-encryption-key" 180 "n8n encryption key"
check_age "${SECRETS_DIR}/n8n-smtp-password" 180 "n8n SMTP password"
check_age "${SECRETS_DIR}/inlock-db-password" 90 "Inlock DB password"

echo ""
echo "=== Certificate Expiry ==="
check_cert_expiry "${SECRETS_DIR}/positive-ssl.crt" "PositiveSSL certificate" 30

echo ""
echo "=== Environment Files (presence/age) ==="
if [[ -f "$ENV_FILE" ]]; then
  check_age "$ENV_FILE" 180 "Infra .env (Cloudflare/Auth0 admin secrets)"
else
  echo "⚠️  Infra .env missing :: ${ENV_FILE}"
  status=1
fi

if [[ -f "$APP_ENV_FILE" ]]; then
  check_age "$APP_ENV_FILE" 60 "App .env.production (NextAuth/Auth0 web secrets)"
else
  echo "⚠️  App .env.production missing :: ${APP_ENV_FILE}"
  status=1
fi

echo ""
if (( status == 0 )); then
  echo "✅ Secret audit passed"
else
  echo "❌ Secret audit found issues"
fi

exit "$status"

