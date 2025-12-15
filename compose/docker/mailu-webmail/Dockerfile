FROM ghcr.io/mailu/webmail:2.0

# Create symlinks for Roundcube files to fix webmail access
# This resolves the "directory index forbidden" error
RUN cd /var/www && \
    ln -sf roundcube/* . && \
    ln -sf /var/www/roundcube/public_html/sso.php /var/www/sso.php && \
    echo "Symlinks created successfully" && \
    ls -la /var/www/ | head -20

# Verify critical symlinks were created
RUN test -L /var/www/sso.php || (echo "sso.php symlink missing!" && exit 1)
RUN test -L /var/www/index.php || (echo "index.php symlink missing!" && exit 1)

# Label the image
LABEL maintainer="inlock.ai"
LABEL description="Mailu webmail with Roundcube symlinks pre-configured"
LABEL version="2.0-custom"
