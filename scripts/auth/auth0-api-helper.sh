#!/bin/bash
# Auth0 Management API Helper Script
# 
# This script provides helper functions for Auth0 Management API operations
# It can use either a provided access token or generate one from credentials
#
# Usage:
#   source ./scripts/auth0-api-helper.sh
#   auth0_get_token  # Get access token
#   auth0_get_app CLIENT_ID  # Get application details
#   auth0_update_callbacks CLIENT_ID "url1,url2"  # Update callback URLs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Load .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

AUTH0_DOMAIN="${AUTH0_DOMAIN:-comzis.eu.auth0.com}"
AUTH0_API_URL="https://${AUTH0_DOMAIN}/api/v2"

# Global variable to store access token
AUTH0_ACCESS_TOKEN=""

# Function to get access token from credentials
auth0_get_token() {
  if [ -z "$AUTH0_MGMT_CLIENT_ID" ] || [ -z "$AUTH0_MGMT_CLIENT_SECRET" ]; then
    echo "Error: Management API credentials not found in .env"
    echo "Please set AUTH0_MGMT_CLIENT_ID and AUTH0_MGMT_CLIENT_SECRET"
    return 1
  fi

  echo "Getting access token..."
  TOKEN_RESPONSE=$(curl -s -X POST "${AUTH0_DOMAIN}/oauth/token" \
    -H "Content-Type: application/json" \
    -d "{
      \"client_id\": \"${AUTH0_MGMT_CLIENT_ID}\",
      \"client_secret\": \"${AUTH0_MGMT_CLIENT_SECRET}\",
      \"audience\": \"${AUTH0_API_URL}/\",
      \"grant_type\": \"client_credentials\"
    }")

  AUTH0_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ] || [ "$AUTH0_ACCESS_TOKEN" = "null" ]; then
    echo "Error: Failed to get access token"
    # Security: Only show error details, not full token response (may contain sensitive data)
    ERROR_CODE=$(echo "$TOKEN_RESPONSE" | jq -r '.error // "unknown"')
    ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // "See Auth0 logs for details"')
    echo "Error: $ERROR_CODE"
    echo "Description: $ERROR_DESC"
    return 1
  fi

  echo "✓ Access token obtained"
  export AUTH0_ACCESS_TOKEN
  return 0
}

# Function to set access token directly
auth0_set_token() {
  AUTH0_ACCESS_TOKEN="$1"
  export AUTH0_ACCESS_TOKEN
}

# Function to get application details
auth0_get_app() {
  local CLIENT_ID="${1:-${AUTH0_ADMIN_CLIENT_ID}}"
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  curl -s -X GET "${AUTH0_API_URL}/applications/${CLIENT_ID}" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" | jq '.'
}

# Function to update application callback URLs
auth0_update_callbacks() {
  local CLIENT_ID="${1:-${AUTH0_ADMIN_CLIENT_ID}}"
  local CALLBACKS="$2"
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  if [ -z "$CALLBACKS" ]; then
    echo "Error: Callback URLs required"
    echo "Usage: auth0_update_callbacks CLIENT_ID \"url1,url2,url3\""
    return 1
  fi

  # Convert comma-separated to JSON array
  CALLBACKS_JSON=$(echo "$CALLBACKS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; ""))')
  
  UPDATE_PAYLOAD=$(jq -n \
    --argjson callbacks "$CALLBACKS_JSON" \
    '{callbacks: $callbacks}')

  echo "Updating callback URLs for application $CLIENT_ID..."
  RESPONSE=$(curl -s -X PATCH "${AUTH0_API_URL}/applications/${CLIENT_ID}" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_PAYLOAD")

  ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
  if [ -n "$ERROR" ]; then
    echo "Error: Failed to update application"
    echo "$RESPONSE" | jq '.'
    return 1
  fi

  echo "✓ Callback URLs updated"
  echo "$RESPONSE" | jq '{name, callbacks}'
}

# Function to update logout URLs
auth0_update_logout_urls() {
  local CLIENT_ID="${1:-${AUTH0_ADMIN_CLIENT_ID}}"
  local LOGOUT_URLS="$2"
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  if [ -z "$LOGOUT_URLS" ]; then
    echo "Error: Logout URLs required"
    echo "Usage: auth0_update_logout_urls CLIENT_ID \"url1,url2,url3\""
    return 1
  fi

  # Convert comma-separated to JSON array
  LOGOUT_JSON=$(echo "$LOGOUT_URLS" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; ""))')
  
  UPDATE_PAYLOAD=$(jq -n \
    --argjson logouts "$LOGOUT_JSON" \
    '{allowed_logout_urls: $logouts}')

  echo "Updating logout URLs for application $CLIENT_ID..."
  RESPONSE=$(curl -s -X PATCH "${AUTH0_API_URL}/applications/${CLIENT_ID}" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_PAYLOAD")

  ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
  if [ -n "$ERROR" ]; then
    echo "Error: Failed to update application"
    echo "$RESPONSE" | jq '.'
    return 1
  fi

  echo "✓ Logout URLs updated"
  echo "$RESPONSE" | jq '{name, allowed_logout_urls}'
}

# Function to list all applications
auth0_list_apps() {
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  curl -s -X GET "${AUTH0_API_URL}/applications" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" | \
    jq -r '.[] | "\(.client_id) - \(.name)"'
}

# Function to get users
auth0_get_users() {
  local QUERY="${1:-}"
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  local URL="${AUTH0_API_URL}/users"
  if [ -n "$QUERY" ]; then
    URL="${URL}?q=${QUERY}"
  fi

  curl -s -X GET "$URL" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" | jq '.'
}

# Function to create a user
auth0_create_user() {
  local EMAIL="$1"
  local PASSWORD="${2:-}"
  local NAME="${3:-}"
  
  if [ -z "$AUTH0_ACCESS_TOKEN" ]; then
    echo "Error: No access token. Run auth0_get_token first or use auth0_set_token"
    return 1
  fi

  if [ -z "$EMAIL" ]; then
    echo "Error: Email required"
    echo "Usage: auth0_create_user EMAIL [PASSWORD] [NAME]"
    return 1
  fi

  CREATE_PAYLOAD=$(jq -n \
    --arg email "$EMAIL" \
    --arg password "$PASSWORD" \
    --arg name "$NAME" \
    '{
      email: $email,
      connection: "Username-Password-Authentication",
      (if $password != "" then "password" else empty end): $password,
      (if $name != "" then "name" else empty end): $name,
      email_verified: true
    }')

  echo "Creating user: $EMAIL"
  RESPONSE=$(curl -s -X POST "${AUTH0_API_URL}/users" \
    -H "Authorization: Bearer ${AUTH0_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$CREATE_PAYLOAD")

  ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
  if [ -n "$ERROR" ]; then
    echo "Error: Failed to create user"
    echo "$RESPONSE" | jq '.'
    return 1
  fi

  echo "✓ User created"
  echo "$RESPONSE" | jq '{user_id, email, name}'
}

# Main execution if script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "Auth0 Management API Helper"
  echo ""
  echo "This script should be sourced to use the functions:"
  echo "  source ./scripts/auth0-api-helper.sh"
  echo ""
  echo "Available functions:"
  echo "  auth0_get_token                    - Get access token from credentials"
  echo "  auth0_set_token TOKEN             - Set access token directly"
  echo "  auth0_get_app [CLIENT_ID]         - Get application details"
  echo "  auth0_update_callbacks CLIENT_ID \"url1,url2\" - Update callback URLs"
  echo "  auth0_update_logout_urls CLIENT_ID \"url1,url2\" - Update logout URLs"
  echo "  auth0_list_apps                  - List all applications"
  echo "  auth0_get_users [QUERY]           - Get users (optional search query)"
  echo "  auth0_create_user EMAIL [PASS] [NAME] - Create a user"
fi

