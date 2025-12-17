# Deployment Guide

## Overview
Deployments are fully automated via GitHub Actions using the `.github/workflows/deploy.yml` pipeline. This architecture ensures consistency, security, and traceability.

## Automation Pipeline
Any push to the `main` branch (or specific Tags in the future) triggers the pipeline:

1.  **Safety Scan**: Trivy checks the codebase for critical vulnerabilities.
2.  **Deploy**:
    *   Connects to the server via SSH.
    *   Syncs code (using `rsync`/`git` strategies).
    *   Restarts containers via `deploy_production.sh`.
3.  **Verify**:
    *   Executes `health_check_remote.sh` on the server.
    *   Retries for up to 3 minutes to ensure services come online.

## Versioning
*   **Current State**: Continuous Deployment (Push to `main` -> Deploy).
*   **Recommended**: Tag-based deployment (e.g., `git tag v1.0.0 && git push origin v1.0.0`).

## Rollback Strategy
If a deployment fails or introduces a critical bug, use **Revert & Re-deploy**:

1.  **Revert**: Locally, revert the bad commit:
    ```bash
    git revert <commit-hash>
    ```
2.  **Push**: Push the reversion to `main`:
    ```bash
    git push origin main
    ```
3.  **Auto-Deploy**: The pipeline will detect the new commit and deploy the previous stable state.

### Emergency Manual Rollback
If the pipeline is broken, you can manually rollback on the server:
```bash
ssh comzis@100.83.222.69
cd /home/comzis/projects/inlock-ai-mvp
git checkout <previous-hash>
./scripts/deploy_production.sh
```

## Troubleshooting
If the `verify` job fails:
1.  Check GitHub Action logs to see which URL failed.
2.  SSH into server and view logs: `docker compose logs -f --tail 100`
3.  Run health check manually: `./scripts/health_check_remote.sh`
