#!/bin/bash
# Preflight checks before infra/service changes.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Preflight Checks ==="

bash "$ROOT_DIR/scripts/health-checks/certificate-health-check.sh"
bash "$ROOT_DIR/scripts/health-checks/service-health-check.sh"
