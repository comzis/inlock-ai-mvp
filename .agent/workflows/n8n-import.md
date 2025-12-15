---
description: Import an N8N workflow JSON directly into the running instance via SSH
---
1.  **Preparation**: Ensure `n8n_sre_key` exists and has correct permissions.
    ```bash
    chmod 600 n8n_sre_key
    ```

2.  **Upload**: Copy the JSON file to the remote server.
    ```bash
    scp -o StrictHostKeyChecking=no -i n8n_sre_key /path/to/local/workflow.json comzis@100.83.222.69:~/workflow.json
    ```

3.  **Injector**: Copy to container and import.
    ```bash
    // turbo
    ssh -o StrictHostKeyChecking=no -i n8n_sre_key comzis@100.83.222.69 "docker cp ~/workflow.json compose-n8n-1:/home/node/workflow.json && docker exec -u node compose-n8n-1 n8n import:workflow --input=/home/node/workflow.json"
    ```
