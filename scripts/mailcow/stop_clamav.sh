#!/bin/bash
# Stop ClamAV Container
# Properly stops ClamAV after disabling it in mailcow.conf

set -euo pipefail

echo "========================================="
echo "Stop ClamAV Container"
echo "========================================="
echo ""
echo "ClamAV is currently running but should be disabled."
echo ""
echo "To stop ClamAV, run on the server:"
echo ""
echo "Option 1: Stop just ClamAV container (Quick)"
echo "---------------------------------------------"
echo "docker stop mailcowdockerized-clamd-mailcow-1"
echo ""
echo "Option 2: Restart all Mailcow services (Recommended)"
echo "-----------------------------------------------------"
echo "cd /home/comzis/mailcow"
echo "docker compose stop"
echo "docker compose up -d"
echo ""
echo "Option 3: Stop and remove ClamAV container"
echo "-------------------------------------------"
echo "docker stop mailcowdockerized-clamd-mailcow-1"
echo "docker rm mailcowdockerized-clamd-mailcow-1"
echo ""
echo "Note: After stopping, ClamAV should NOT restart automatically"
echo "if SKIP_CLAMD=y is set in mailcow.conf."
