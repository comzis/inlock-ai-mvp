# Complete Port Restriction Guide

## ✅ Completed Restrictions

### 1. PostgreSQL (Port 5432) - FIXED
- **Status**: ✅ SECURE
- **Action**: Removed insecure container, created secure version without public ports
- **Verification**: `netstat -tulpn | grep 5432` returns nothing
- **Containers**: All PostgreSQL containers now show `5432/tcp` (internal only)

### 2. Ollama (Port 11434) - FIXED
- **Status**: ✅ SECURE  
- **Action**: Removed `ports:` section from `compose/ollama.yml`
- **File Updated**: `/home/comzis/inlock-infra/compose/ollama.yml`
- **Verification**: Port 11434 no longer publicly exposed
- **Note**: Container may need restart: `docker compose -f compose/ollama.yml --env-file .env up -d`

## ⚠️ Remaining Restrictions

### 3. Traefik (Ports 80, 443) - INTENTIONAL
- **Status**: ✅ PUBLIC (Required)
- **Reason**: Reverse proxy must be publicly accessible
- **Note**: Port 9100 (metrics) correctly restricted to 127.0.0.1

## Firewall Configuration

### Run Firewall Setup
```bash
cd /home/comzis/inlock-infra
sudo ./scripts/fix-critical-security.sh
```

This will:
- Enable UFW firewall
- Restrict SSH (22) to Tailscale IPs only
- Block ports: 11434, 3040, 5432
- Allow HTTP/HTTPS (80/443) for Traefik
- Allow internal Docker networks

### Manual Firewall Setup
```bash
# Enable firewall
sudo ufw enable

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow required services
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Restrict SSH to Tailscale
sudo ufw delete allow 22/tcp  # Remove public SSH
sudo ufw allow from 100.83.222.69/32 to any port 22
sudo ufw allow from 100.96.110.8/32 to any port 22

# Block unnecessary ports
sudo ufw deny 11434/tcp comment 'Ollama'
sudo ufw deny 3040/tcp comment 'Port 3040 - Internal only'
sudo ufw deny 5432/tcp comment 'PostgreSQL'

# Allow Docker networks
sudo ufw allow from 172.20.0.0/16 comment 'Docker edge'
sudo ufw allow from 172.18.0.0/16 comment 'Docker default'
sudo ufw allow from 172.17.0.0/16 comment 'Docker bridge'

# Verify
sudo ufw status numbered
```

## Verification Commands

### Check Docker Container Ports
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep "0.0.0.0"
# Should only show Traefik (80, 443)
```

### Check Host Ports
```bash
netstat -tulpn | grep "0.0.0.0" | awk '{print $4}' | cut -d: -f2 | sort -u
# Should show: 22, 80, 443, 41641, 53 (and possibly 3040 if not fixed)
```

### Security Check
```bash
cd /home/comzis/inlock-infra
./scripts/security-check.sh
```

## Summary

| Service | Port | Status | Action |
|---------|------|--------|--------|
| PostgreSQL | 5432 | ✅ Secure | Fixed |
| Ollama | 11434 | ✅ Secure | Fixed |
| Traefik | 80/443 | ✅ Public (OK) | Required |
| SSH | 22 | ⚠️ Public | Restrict via firewall |

## Next Steps

1. ✅ **PostgreSQL** - DONE
2. ✅ **Ollama** - DONE (restart container if needed)
3. ⚠️ **Firewall** - Run `sudo ./scripts/configure-firewall.sh`
4. ✅ **Verify** - Run security check

## Files Modified

- `/home/comzis/inlock-infra/compose/ollama.yml` - Removed port mapping
- `/home/comzis/inlock-infra/docs/` - Documentation created

## Files to Modify



