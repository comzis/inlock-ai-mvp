#!/usr/bin/env bash
# Fix Portainer permissions and restart
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart portainer
echo "✅ Portainer fixed and restarted"
