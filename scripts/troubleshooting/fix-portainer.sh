#!/bin/bash
echo "Fixing Portainer ownership..."
sudo chown -R 1000:1000 /home/comzis/apps/traefik/portainer_data
sudo chmod 755 /home/comzis/apps/traefik/portainer_data
cd /home/comzis/inlock-infra
docker compose -f compose/stack.yml --env-file .env restart portainer
echo "✅ Portainer ownership fixed and restarted"
