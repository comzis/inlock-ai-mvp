# Traefik Configuration Guide

Configure **Traefik** reverse proxy for Inlock AI services with SSL/TLS and authentication.

## Overview

Traefik manages:
- **Reverse proxy** for all services
- **SSL/TLS certificates** via Let's Encrypt
- **OAuth2 authentication** via Auth0
- **Load balancing** and routing

## Configuration Files

### Router Configuration

Main router config: [`infrastructure/traefik/routers.yml`](file:///home/comzis/.gemini/antigravity/scratch/inlock-ai/infrastructure/traefik/routers.yml)

This file defines routes for:
- **Admin services**: Traefik dashboard, Portainer, Coolify, n8n, Grafana, Homarr
- **Tooling**: CMS and Analytics (defined via container labels)
- **Main app**: Inlock AI application
- **Auth**: OAuth2-proxy for Auth0 integration

### Tooling Routers

Tooling-specific routes: [`infrastructure/traefik/tooling-routers.yml`](file:///home/comzis/.gemini/antigravity/scratch/inlock-ai/infrastructure/traefik/tooling-routers.yml)

## Deploying Router Configurations

### Via Docker Config

```bash
# Create or update Traefik config
docker config create traefik_routers_v2 infrastructure/traefik/routers.yml

# Update Traefik service to use config
docker service update \
  --config-rm traefik_routers_v1 \
  --config-add source=traefik_routers_v2,target=/etc/traefik/dynamic/routers.yml \
  traefik
```

### Via File Provider

If using file provider, copy to Traefik config directory:

```bash
cp infrastructure/traefik/routers.yml /path/to/traefik/dynamic/routers.yml
cp infrastructure/traefik/tooling-routers.yml /path/to/traefik/dynamic/tooling-routers.yml
```

## SSL/TLS Configuration

### Certificate Resolvers

Traefik uses two certificate resolvers:

1. **`le-dns`**: DNS-01 challenge for wildcard certificates
2. **`le-tls`**: TLS-01 challenge for standard certificates

Example router with SSL:

```yaml
http:
  routers:
    example:
      entryPoints:
        - websecure
      rule: Host(`example.inlock.ai`)
      service: example
      tls:
        certResolver: le-dns
```

### Positive SSL Certificates

For the main domain (`inlock.ai`), Positive SSL is configured:

```yaml
tls:
  options: default  # Uses Positive SSL certificate
```

## Auth0 Integration

### OAuth2-Proxy Setup

Protected routes use `admin-forward-auth` middleware:

```yaml
middlewares:
  - secure-headers
  - admin-forward-auth
  - allowed-admins
```

**Components:**
- **`oauth2-proxy`**: Handles Auth0 authentication
- **`admin-forward-auth`**: Forward auth middleware
- **`allowed-admins`**: Email whitelist

### Configuration

OAuth2-proxy service must be configured with:

```env
OAUTH2_PROXY_PROVIDER=oidc
OAUTH2_PROXY_CLIENT_ID=<auth0-client-id>
OAUTH2_PROXY_CLIENT_SECRET=<auth0-client-secret>
OAUTH2_PROXY_OIDC_ISSUER_URL=https://<tenant>.auth0.com/
OAUTH2_PROXY_REDIRECT_URL=https://auth.inlock.ai/oauth2/callback
OAUTH2_PROXY_EMAIL_DOMAINS=*
OAUTH2_PROXY_COOKIE_SECRET=<random-32-byte-secret>
```

## Service Configuration

### Adding a New Service

1. **In Docker Compose**, add Traefik labels:

```yaml
services:
  myservice:
    image: myapp:latest
    networks:
      - traefik_public
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.inlock.ai`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls.certresolver=le-dns"
      - "traefik.http.services.myservice.loadbalancer.server.port=80"
```

2. **Or in router config file:**

```yaml
http:
  routers:
    myservice:
      entryPoints:
        - websecure
      rule: Host(`myservice.inlock.ai`)
      middlewares:
        - secure-headers
      service: myservice
      tls:
        certResolver: le-dns

  services:
    myservice:
      loadBalancer:
        servers:
          - url: "http://myservice:80"
```

### Protected Service (Auth Required)

```yaml
http:
  routers:
    protected-service:
      entryPoints:
        - websecure
      rule: Host(`protected.inlock.ai`)
      middlewares:
        - secure-headers
        - admin-forward-auth
        - allowed-admins
        - mgmt-ratelimit
      service: protected-service
      tls:
        certResolver: le-dns
```

## Middlewares

### Security Headers

```yaml
middlewares:
  secure-headers:
    headers:
      sslRedirect: true
      stsSeconds: 31536000
      stsIncludeSubdomains: true
      stsPreload: true
      forceSTSHeader: true
```

### Rate Limiting

```yaml
middlewares:
  mgmt-ratelimit:
    rateLimit:
      average: 100
      burst: 50
```

## Troubleshooting

### Certificate Issues

**Check certificate resolver:**
```bash
docker exec traefik cat /letsencrypt/acme.json
```

**Force certificate renewal:**
```bash
docker exec traefik rm /letsencrypt/acme.json
docker restart traefik
```

### Routing Issues

**Check Traefik logs:**
```bash
docker logs traefik -f
```

**Verify service registration:**
Visit Traefik dashboard at `https://traefik.inlock.ai/dashboard/`

### Auth0 Callback Errors

1. Verify redirect URL in Auth0 dashboard matches `https://auth.inlock.ai/oauth2/callback`
2. Check OAuth2-proxy logs: `docker logs oauth2-proxy`
3. Verify allowed email domains configuration

## Network Configuration

All services must be on the `traefik_public` network:

```yaml
networks:
  traefik_public:
    external: true
```

Create if it doesn't exist:
```bash
docker network create traefik_public
```

## Best Practices

1. **Use DNS-01 challenge** for wildcard certificates
2. **Enable rate limiting** on admin interfaces
3. **Require auth** for sensitive services
4. **Use secure headers** middleware on all routes
5. **Set appropriate priorities** for overlapping rules
6. **Monitor certificate expiration** via Traefik dashboard

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
