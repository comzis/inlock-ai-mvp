# Mailu Custom Configuration

## Overview

This document describes the custom configurations applied to the Mailu email stack to fix persistent issues with webmail access and email functionality.

## Custom Modifications

### 1. Custom Admin Image (SSO Fix)

**Issue**: Mailu SSO was redirecting to `/admin` (404) instead of `/webmail/` when the URL contained `?homepage` parameter.

**Solution**: Custom Docker image with patched SSO code.

**Location**: `compose/docker/mailu-admin/Dockerfile`

**Patch Applied**:
```python
# Changed in /app/mailu/sso/views/base.py
if False and 'homepage' in flask.request.url and not is_proxied:
    return None
```

### 2. Custom Webmail Image (Symlinks)

**Issue**: Roundcube files not accessible, causing "directory index forbidden" errors.

**Solution**: Custom Docker image with symlinks pre-created.

**Location**: `compose/docker/mailu-webmail/Dockerfile`

**Symlinks Created**:
- `/var/www/*` → `/var/www/roundcube/*`
- `/var/www/sso.php` → `/var/www/roundcube/public_html/sso.php`

### 3. Roundcube SMTP Configuration

**Issue**: Roundcube trying to use TLS in `notls` mode, causing email sending failures.

**Solution**: Volume-mounted configuration file.

**Location**: `compose/config/roundcube-smtp-config.inc.php`

**Configuration**:
```php
$config['smtp_server'] = 'front';
$config['smtp_port'] = 25;
$config['smtp_conn_options'] = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    ),
);
```

## Deployment

### Building Custom Images

```bash
cd compose
./scripts/build-custom-images.sh
```

### Deploying Mailu

```bash
cd compose
./scripts/deploy-mailu.sh
```

### Manual Deployment

```bash
cd compose
docker compose -f mailu.yml down
docker compose -f mailu.yml build
docker compose -f mailu.yml up -d
```

## Verification

### Check Custom Images

```bash
docker images | grep mailu
```

Expected output:
```
mailu-admin-patched    2.0    ...
mailu-webmail-custom   2.0    ...
```

### Verify SSO Patch

```bash
docker exec compose-mailu-admin-1 grep "if False and 'homepage'" /app/mailu/sso/views/base.py
```

### Verify Webmail Symlinks

```bash
docker exec compose-mailu-webmail-1 ls -la /var/www/sso.php
docker exec compose-mailu-webmail-1 ls -la /var/www/index.php
```

### Verify SMTP Config

```bash
docker exec compose-mailu-webmail-1 cat /overrides/roundcube-smtp.inc.php
```

## Maintenance

### Updating Base Images

When Mailu releases new versions:

1. Update the base image SHA in Dockerfiles
2. Rebuild custom images
3. Test thoroughly before deploying

```bash
# Update Dockerfile FROM lines
# Then rebuild
./scripts/build-custom-images.sh
./scripts/deploy-mailu.sh
```

### Rollback Procedure

If issues occur:

```bash
# Edit mailu.yml to use original images
# Comment out build sections, uncomment original image lines
docker compose -f mailu.yml down
docker compose -f mailu.yml up -d
```

## Troubleshooting

### Webmail 404 Error

Check if SSO patch is applied:
```bash
docker exec compose-mailu-admin-1 grep "if False" /app/mailu/sso/views/base.py
```

### Email Sending Fails

Check SMTP config is mounted:
```bash
docker exec compose-mailu-webmail-1 test -f /var/www/roundcube/config/config-smtp.inc.php && echo "Config exists"
```

### Symlinks Missing

Rebuild webmail image:
```bash
docker compose -f mailu.yml build mailu-webmail
docker compose -f mailu.yml up -d mailu-webmail
```

## Files

- `compose/docker/mailu-admin/Dockerfile` - Custom admin image
- `compose/docker/mailu-webmail/Dockerfile` - Custom webmail image
- `compose/config/roundcube-smtp-config.inc.php` - SMTP configuration
- `compose/scripts/build-custom-images.sh` - Build script
- `compose/scripts/deploy-mailu.sh` - Deployment script
- `compose/mailu.yml` - Docker Compose configuration

## References

- [Mailu Documentation](https://mailu.io/)
- [Roundcube Documentation](https://github.com/roundcube/roundcubemail/wiki)
