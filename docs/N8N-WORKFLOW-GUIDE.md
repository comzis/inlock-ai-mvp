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
2.  Click on the **Workflows** menu.
3.  Click the **... (More Options)** button in the top right or "Add Workflow".
4.  Select **Import from File**.
5.  Upload the `compose/n8n-health-check-workflow.json` file from this repository.
    -   *If you are on a different machine, copy the content of the JSON file and use "Import from URL" or "Import from JSON" if available.*

### 2. Configure OpenAI Credentials

The workflow uses an "AI SRE Agent" node that requires OpenAI credentials.

1.  Double-click the **AI SRE Agent** node.
2.  Under **Credential to connect with**, select **Create New Credential**.
3.  Search for "OpenAI API".
4.  Enter your OpenAI API Key.
    -   *Note: Ensure you have credits in your OpenAI account.*
5.  Save the credential.

### 3. Configure Alerting (Optional)

The workflow ends with a "Send Alert (Config Required)" node which does nothing by default.

1.  Delete the "Send Alert" node and replace it with your preferred notification node:
    -   **Email**: Use the "Send Email" node.
    -   **Slack**: Use the "Slack" node.
    -   **Discord**: Use the "Discord" node.
2.  Connect the output of "AI SRE Agent" to your new notification node.
3.  Map the output of the AI Agent (the analysis text) to the message body of your notification.
    -   Expression: `{{ $json.content }}` (or drag and drop the output).

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
