# Ansible Automation – INLOCK.AI

This directory provisions and maintains the Docker stack, applies host hardening, and coordinates backups.

## Prerequisites
- Ansible 2.16+
- community.docker & community.general collections (`ansible-galaxy collection install community.docker community.general`)
- SSH access to target hosts with `become` privileges
- `.env` + secrets populated at the repository root (used by templates and compose deploys)

## Inventory
`inventories/hosts.yml` defines host groups:
- `edge` – public-facing Traefik nodes
- `mgmt` – Portainer/monitoring hosts
- `db` – Postgres/Redis backing services

Update the inventory with real hostnames/IPs.

## Playbooks
- `playbooks/deploy.yml` – copies Traefik + Compose configs and runs `docker compose` to reconcile the stack
- `playbooks/hardening.yml` – applies SSH/Docker/system hardening via roles + scripts
- `playbooks/backup.yml` – triggers restic/WAL-G backups for critical data

## Usage
```
ansible-playbook -i inventories/hosts.yml playbooks/hardening.yml --limit edge
ansible-playbook -i inventories/hosts.yml playbooks/deploy.yml -e env_file=/opt/inlock/.env
ansible-playbook -i inventories/hosts.yml playbooks/backup.yml --limit mgmt
```

Secrets should be sourced from Vault/SOPS and only referenced via Ansible vault or `_FILE` env vars; never commit raw credentials. See `docs/devops/server-hardening.md` for additional guidance.
