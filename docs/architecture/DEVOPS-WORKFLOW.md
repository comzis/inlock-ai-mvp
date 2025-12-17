# Inlock AI - DevOps Architecture & Workflow

This document illustrates the complete DevOps lifecycle, from local development to production deployment, highlighting key components and security boundaries.

```mermaid
graph TD
    subgraph Local_Environment["💻 Local Environment (Mac)"]
        LocalFile[".env.development"]
        LocalCompose["docker-compose.local.yml"]
        Dev[("Developer")] --> |Writes Code| LocalCode["Source Code"]
        LocalCode --> |Test| LocalStack["Local Docker Stack"]
        LocalStack -.-> LocalFile
        LocalStack -.-> LocalCompose
    end

    subgraph GitHub_Ecosystem["☁️ GitHub Ecosystem"]
        Repo["Git Repository (Main)"]
        Actions["GitHub Actions (CI/CD)"]
        GHSecrets[("GitHub Secrets")]
        
        Dev --> |git push| Repo
        Repo --> |Trigger| Actions
        Actions -.-> |Read Creds| GHSecrets
        Actions --> |1. Trivy Scan| SecurityReport["Security Audit"]
        Actions --> |2. SSH Deploy| RemoteServer
        Actions --> |3. Verify Health| HealthCheck["Health Check Script"]
    end

    subgraph Production_Server["🏢 Remote Server (100.83.222.69)"]
        subgraph Host_OS["Host OS (Ubuntu)"]
            DeployScript["scripts/deploy_production.sh"]
            EnvFile[".env (Production)"]
            HostSecrets["/apps/secrets-real/"]
            
            Actions -.-> |Execute| DeployScript
        end
        
        subgraph Docker_Swarm["🐳 Docker Runtime"]
            Stack["Docker Compose Stack"]
            Containers["Services (N8N, Mailu, Traefik)"]
            
            DeployScript --> |docker compose up| Stack
            Stack --> Containers
            Containers -.-> |Mount Read-Only| HostSecrets
            Containers -.-> |Read Env| EnvFile
        end
    end

    %% Security & Flow Lines
    GHSecrets -- "SSH_KEY, SSH_HOST" --> Actions
    DeployScript -- "Pull Updates" --> Repo
    
    style Local_Environment fill:#e1f5fe,stroke:#01579b
    style GitHub_Ecosystem fill:#f3e5f5,stroke:#4a148c
    style Production_Server fill:#e8f5e9,stroke:#1b5e20
    style HostSecrets fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px
    style GHSecrets fill:#ffcdd2,stroke:#b71c1c,stroke-width:2px
```

![DevOps Workflow Diagram](devops_workflow.png)

## Recommended Practices

### 1. Local Development
*   **Use `docker-compose.local.yml`**: Do not try to run the production stack locally. The local compose file is optimized for macOS networking and performance.
*   **`.env.development`**: Keep a local-only env file for dev keys. Never commit this.

### 2. Secret Management
*   **Production**: Store actual secrets (API keys, DB passwords) in `/home/comzis/apps/secrets-real/` on the server.
*   **Injection**: These are mounted into containers as Docker Secrets (files), typically at `/run/secrets/<name>`.
*   **Environment Variables**: Use `.env` *only* for non-sensitive config (domain names, flags).

### 3. Deployment Flow
1.  **Commit**: Changes pushed to `main` trigger the pipeline.
2.  **Scan**: Trivy scans for vulnerabilities.
3.  **Deploy**: GitHub Actions SSHs into the server and runs `deploy_production.sh`.
4.  **Verify**: The pipeline runs `health_check_remote.sh` to confirm the site is up.
