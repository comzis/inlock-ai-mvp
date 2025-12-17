# Secret Management Strategy

## Use Case Definition
*   **Configuration**: Non-sensitive settings (Domain names, Feature flags, Port numbers).
*   **Secrets**: Sensitive credentials (Passwords, API Keys, Certificates).

## The Inlock Standard

### 1. Configuration: `.env` Files
*   **Location**: `/home/comzis/deployments/.env` (Production)
*   **Usage**: `env_file:` in `docker-compose.yml`
*   **Permissions**: `600` (Owner Read/Write)

### 2. Secrets: Docker Swarm/Compose Secrets
*   **Location**: `/home/comzis/apps/secrets-real/` (Host)
*   **Usage**: `secrets:` in `docker-compose.yml`
*   **Permissions**: `644` (Owner Read/Write, World Read - **Required for Container Bind Mounts**)
    *   *Note*: Containers run as non-root users. If file is 600, `mailu` user cannot read root-owned secret file.

### 🚫 Forbidden Practices
*   **Hardcoding**: Never commit secrets to git.
*   **ENV Variables for Passwords**: Avoid passing passwords via `-e` or `.env` if possible (Docker Inspect reveals them). Use `_FILE` variants supported by images (e.g., `POSTGRES_PASSWORD_FILE`).

## How to Add a New Secret
1.  **On Host**: `echo "my-secret-value" > /home/comzis/apps/secrets-real/my-new-secret`
2.  **In Compose**:
    ```yaml
    secrets:
      my-new-secret:
        file: /home/comzis/apps/secrets-real/my-new-secret
    services:
      app:
        secrets:
          - my-new-secret
        environment:
          - API_KEY_FILE=/run/secrets/my-new-secret
    ```
