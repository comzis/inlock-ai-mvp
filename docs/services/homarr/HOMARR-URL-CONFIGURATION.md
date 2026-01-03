# Homarr URL Configuration Guide

**Date:** 2025-12-29  
**Issue:** Homarr auto-detects Docker containers but sets URLs to `localhost:port` by default

---

## Problem

When Homarr discovers Docker containers via the Docker socket, it automatically sets their URLs to `http://localhost:PORT` because it cannot determine the external hostnames. These URLs need to be manually updated to the correct domain names.

---

## Solution: Manual URL Updates

You need to manually update each app's URL in Homarr's interface.

### Steps:

1. **Access Homarr Dashboard:**
   - Go to `https://dashboard.inlock.ai`
   - Authenticate with Auth0 if needed

2. **Enter Edit Mode:**
   - Click the pencil/edit icon in the top-right corner

3. **Update Each Application:**
   - Click on the application tile you want to edit
   - Find the "URL" field in the settings
   - Replace `http://localhost:PORT` with the correct HTTPS URL from the table below
   - Save the changes

4. **Repeat for all applications**

---

## Service URL Reference

Use these URLs when configuring apps in Homarr:

| Service | Container Name | Port | Correct URL | Notes |
|---------|---------------|------|-------------|-------|
| **Portainer** | `portainer` | 9000 | `https://portainer.inlock.ai` | Container management |
| **n8n** | `n8n` | 5678 | `https://n8n.inlock.ai` | Workflow automation |
| **Grafana** | `grafana` | 3000 | `https://grafana.inlock.ai` | Monitoring dashboards |
| **Coolify** | `coolify` | 8080 | `https://deploy.inlock.ai` | Deployment platform |
| **Homarr** | `homarr` | 7575 | `https://dashboard.inlock.ai` | This dashboard |
| **Cockpit** | Host service | 9090 | `https://cockpit.inlock.ai` | Server management |
| **Traefik Dashboard** | `traefik` | 8080 | `https://traefik.inlock.ai/dashboard/` | Traefik UI |
| **Inlock AI** | `inlock-ai` | 3040 | `https://inlock.ai` | Main application |
| **Mailcow** | `mailu-front` | 80 | `https://mail.inlock.ai` | Email server |

### Notes:

- **All URLs use HTTPS** (not HTTP)
- **All admin services** require Auth0 authentication
- **Port numbers** are internal Docker ports, not exposed externally
- Services are accessed via their domain names through Traefik reverse proxy

---

## Common Mappings

If Homarr auto-detects these containers, here are the correct URLs:

### Admin Services (Protected with Auth0):
```
portainer:9000  → https://portainer.inlock.ai
n8n:5678        → https://n8n.inlock.ai
grafana:3000    → https://grafana.inlock.ai
coolify:8080    → https://deploy.inlock.ai
cockpit:9090    → https://cockpit.inlock.ai
traefik:8080    → https://traefik.inlock.ai/dashboard/
```

### Public Services:
```
inlock-ai:3040  → https://inlock.ai
mailu-front:80  → https://mail.inlock.ai
```

---

## Why This Happens

Homarr reads Docker container information via the mounted Docker socket (`/var/run/docker.sock`). When it discovers containers, it can see:
- Container names
- Exposed ports
- Network information

However, it **cannot determine**:
- External domain names (configured in Traefik)
- Whether services use HTTPS or HTTP
- Reverse proxy routing rules

Therefore, it defaults to `http://localhost:PORT`, which must be manually corrected.

---

## Future Improvements

### Potential Solutions:

1. **Manual Configuration:** Continue updating URLs manually in Homarr UI (current approach)

2. **Homarr Environment Variables:** If Homarr adds support for default URL patterns or domain mappings in future versions, we can configure them

3. **Homarr Configuration File:** Check if Homarr's config file (`homarr_configs` volume) can be edited directly to set default URLs

4. **Custom Integration Script:** Create a script that updates Homarr's database/config with correct URLs after container discovery

---

## Verification

After updating URLs:

1. **Test Each Link:**
   - Click each app tile in Homarr
   - Verify it opens the correct service
   - Ensure authentication works (for admin services)

2. **Check URL Format:**
   - All should use `https://` (not `http://`)
   - Should use domain names (not `localhost` or IP addresses)
   - Should not include port numbers in the URL

---

## Quick Reference Card

**Copy-paste these URLs when editing apps in Homarr:**

```
Portainer:  https://portainer.inlock.ai
n8n:        https://n8n.inlock.ai
Grafana:    https://grafana.inlock.ai
Coolify:    https://deploy.inlock.ai
Cockpit:    https://cockpit.inlock.ai
Traefik:    https://traefik.inlock.ai/dashboard/
Inlock AI:  https://inlock.ai
Mailcow:    https://mail.inlock.ai
```

---

**Last Updated:** 2025-12-29











