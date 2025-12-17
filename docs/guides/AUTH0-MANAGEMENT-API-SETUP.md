# Auth0 Management API Setup Guide

This guide will help you set up Auth0 Management API access for automation tasks.

## Step 1: Create Machine-to-Machine Application in Auth0

1. **Go to Auth0 Dashboard**: https://manage.auth0.com/
2. **Navigate to Applications**: Applications → Applications
3. **Create Application**:
   - Click "Create Application"
   - Name: `inlock-management-api` (or your preferred name)
   - Type: **Machine to Machine Applications**
   - Click "Create"

## Step 2: Authorize Management API Access

1. **Select API**: After creating, you'll be prompted to select an API
   - Choose **Auth0 Management API**
   - Click "Authorize"

2. **Select Permissions (Scopes)**:
   - `read:applications` - Read application settings
   - `update:applications` - Update application settings
   - `read:users` - Read user information (optional, for user management)
   - `create:users` - Create users (optional)
   - `update:users` - Update users (optional)
   - `delete:users` - Delete users (optional)
   - `read:clients` - Read client information
   - `update:clients` - Update client information
   
   **Minimum required for automation:**
   - `read:applications`
   - `update:applications`

3. **Click "Authorize"**

## Step 3: Get Credentials

1. **Go to Application Settings**:
   - Applications → Applications → `inlock-management-api`
   - Copy the **Client ID**
   - Copy the **Client Secret** (click "Show" to reveal)

## Step 4: Add Credentials to .env

Add these to your `.env` file:

```bash
AUTH0_MGMT_CLIENT_ID=your-management-api-client-id
AUTH0_MGMT_CLIENT_SECRET=your-management-api-client-secret
```

## Step 5: Test API Access

Run the test script:

```bash
./scripts/test-auth0-api.sh
```

Or manually test:

```bash
curl -X POST "https://comzis.eu.auth0.com/oauth/token" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "YOUR_MGMT_CLIENT_ID",
    "client_secret": "YOUR_MGMT_CLIENT_SECRET",
    "audience": "https://comzis.eu.auth0.com/api/v2/",
    "grant_type": "client_credentials"
  }'
```

## Step 6: Use for Automation

Once set up, you can use the Management API to:

- Update application callback URLs automatically
- Manage users programmatically
- Configure applications
- Monitor and audit changes
- Automate Auth0 configuration tasks

## Example: Update Application Callback URLs

```bash
./scripts/configure-auth0-api.sh
```

This will automatically update the callback URLs for your admin application.

## Security Notes

- **Never commit** Management API credentials to git
- Store credentials in `.env` file (already in .gitignore)
- Use least privilege principle - only grant necessary scopes
- Rotate credentials periodically
- Monitor API usage in Auth0 Dashboard

## Troubleshooting

**Error: "access_denied"**
- Check that the application is authorized for Management API
- Verify scopes are selected correctly
- Ensure credentials are correct

**Error: "invalid_client"**
- Verify Client ID and Secret are correct
- Check that the application type is "Machine to Machine"

**Error: "insufficient_scope"**
- Add the required scopes in Auth0 Dashboard
- Re-authorize the application

