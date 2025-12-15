FROM ghcr.io/mailu/admin@sha256:97bc9dc7259c485fcf20bf86809b17e3aee1b236662c2ebee1f2d6c825801400

# Apply SSO homepage redirect fix
# This fixes the bug where SSO redirects to /admin instead of /webmail when URL contains ?homepage
RUN sed -i "s/if 'homepage' in flask.request.url and not is_proxied:/if False and 'homepage' in flask.request.url and not is_proxied:/" \
    /app/mailu/sso/views/base.py

# Verify patch was applied successfully
RUN grep -q "if False and 'homepage'" /app/mailu/sso/views/base.py || (echo "SSO patch failed!" && exit 1)

# Label the image
LABEL maintainer="inlock.ai"
LABEL description="Mailu admin with SSO homepage redirect fix"
LABEL version="2.0-patched"
