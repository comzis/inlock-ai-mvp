# N8N Health Check Workflow Guide

This guide explains how to import and configure the automated health check workflow in your n8n instance.

## Overview

The workflow performs the following actions:
1.  **Scheduled Trigger**: Runs every hour.
2.  **Health Checks**: Pings key services:
    -   `https://inlock.ai` (Homepage)
    -   `https://n8n.inlock.ai` (n8n External)
    -   `http://traefik:8080/ping` (Internal Traefik)
    -   `http://portainer:9000` (Internal Portainer)
3.  **Analysis**: If any service fails (does not return 200 OK), it triggers the AI Agent.
4.  **AI Agent**: Uses OpenAI (GPT-4o) to analyze the failure and suggest fixes.
5.  **Alerting**: (Placeholder) Can be connected to Email, Slack, or Discord.

## Installation Steps

### 1. Import the Workflow

1.  Log in to your n8n instance at `https://n8n.inlock.ai`.
2.  If you see the "Welcome Admin!" screen:
    -   Click **Start from scratch**.
    -   This opens the empty workflow editor.
3.  Once inside the editor:
    -   **Method A (Easiest)**: Open `compose/n8n-health-check-workflow.json` in your editor, copy the entire content, click on the n8n canvas, and **PASTE** (Ctrl+V or Cmd+V) directly.
    -   **Method B**: Click the three dots **(...)** in the top right corner of the n8n editor -> **Import from File** -> Select `compose/n8n-health-check-workflow.json`.
    -   *If the three dots are not visible: click "Workflow" in the left sidebar first.*

### 2. Configure OpenAI Credentials

The workflow uses an "AI SRE Agent" node that requires OpenAI credentials.

1.  Double-click the **AI SRE Agent** node.
2.  Under **Credential to connect with**, select **Create New Credential**.
3.  Search for "OpenAI API".
4.  Enter your OpenAI API Key.
    -   *Note: Ensure you have credits in your OpenAI account.*
5.  Save the credential.

### 3. Configure Email Alerting

The workflow now includes a "Send Email Alert" node. You need to configure the SMTP credentials for `admin@inlock.ai`.

1.  Double-click the **Send Email Alert** node (at the end of the workflow).
2.  Under **Credential for SMTP**, select **Create New Credential**.
3.  Enter the following details:
    -   **User**: `admin@inlock.ai`
    -   **Password**: *Enter your Mailu Admin Password* (Use `./scripts/show-credentials.sh` if needed to find where it is stored, or check your password manager).
    -   **Host**: `mail.inlock.ai`
    -   **Port**: `587`
    -   **Secure**: `StartTLS` (or TLS)
4.  Save the credential.
5.  Close the node.

*Note: The email will only be sent if the "Is Healthy?" check fails.*

## Testing

1.  Click **Execute Workflow** at the bottom of the canvas.
2.  All "Check" nodes should run successfully and flow to the "Healthy - Do Nothing" path.
3.  **To specific test the AI Agent**:
    -   Temporarily modify one of the "Check" nodes (e.g., "Check Homepage") to use a fake URL (e.g., `https://inlock.ai/non-existent-page-404`).
    -   Run the workflow again.
    -   It should follow the "False" path of "Is Healthy?" and trigger the AI Agent.
    -   Check the output of the AI Agent to see the incident report.

## Troubleshooting

-   **Workflow fails immediately**: Check if the "Code" node logic is compatible with your specific n8n version. The provided code is standard JavaScript but n8n sometimes updates data structures.
-   **AI Agent fails**: Check your OpenAI API Key and quota.
