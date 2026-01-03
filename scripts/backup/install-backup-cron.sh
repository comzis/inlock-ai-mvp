#!/usr/bin/env bash
set -euo pipefail

# Installs a daily cron job (03:00) to run the automated backup script.
# Idempotent: if the line already exists, it is not duplicated.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/backup/automated-backup-system.sh"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"
CRON_LINE="0 3 * * * ${SCRIPT} >> ${LOG_FILE} 2>&1"

mkdir -p "${LOG_DIR}"

TMP_CRON="$(mktemp)"
if crontab -l >/dev/null 2>&1; then
  crontab -l >"${TMP_CRON}"
fi

if ! grep -Fq "${CRON_LINE}" "${TMP_CRON}"; then
  echo "${CRON_LINE}" >>"${TMP_CRON}"
  crontab "${TMP_CRON}"
  echo "Installed cron entry: ${CRON_LINE}"
else
  echo "Cron entry already present."
fi

rm -f "${TMP_CRON}"


