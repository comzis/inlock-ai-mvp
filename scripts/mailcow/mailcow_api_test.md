# Mailcow API Test Results

**Date**: 2026-01-11  
**Test**: Mailcow API Authentication and Endpoints

---

## Test Summary

✅ **API Endpoint Accessible**: `https://mail.inlock.ai/api/`  
✅ **API Responds**: HTTP 200  
❌ **Basic Auth Fails**: Username/password authentication doesn't work  
✅ **API Key Required**: API uses `X-API-Key` header for authentication

---

## Test Results

### 1. API Endpoint Availability

```bash
curl https://mail.inlock.ai/api/
```

**Result**: ✅ HTTP 200 (Swagger UI documentation)

The API endpoint serves Swagger UI documentation, indicating the API is active.

### 2. Basic Authentication Test

```bash
curl -u "admin:MailcowAdmin123!" https://mail.inlock.ai/api/v1/get/status
```

**Result**: ❌ HTTP 200 but empty response (0 bytes)

The API accepts the request but returns empty content, indicating Basic Auth is not the correct authentication method.

### 3. API Authentication Method

**Response Headers Show**:
```
access-control-allow-headers: Accept, Content-Type, X-Api-Key, Origin
```

This confirms the API expects the `X-API-Key` header for authentication, not Basic Auth.

---

## How to Use Mailcow API

### Step 1: Generate API Key

1. **Login to Admin Panel**:
   - URL: `https://mail.inlock.ai/admin`
   - Username: `admin`
   - Password: `MailcowAdmin123!`

2. **Navigate to API Settings**:
   - Go to: **Configuration** → **System** → **API**
   - Or: **Configuration** → **API**

3. **Generate API Key**:
   - Click "Add API Key" or "Generate API Key"
   - Save the generated API key securely

### Step 2: Use API Key

Once you have the API key, use it with the `X-API-Key` header:

```bash
# Test API access
curl -H "X-API-Key: YOUR_API_KEY" https://mail.inlock.ai/api/v1/get/status

# Get system info
curl -H "X-API-Key: YOUR_API_KEY" https://mail.inlock.ai/api/v1/get/system/info

# List mailboxes
curl -H "X-API-Key: YOUR_API_KEY" https://mail.inlock.ai/api/v1/get/mailbox/all

# Get domains
curl -H "X-API-Key: YOUR_API_KEY" https://mail.inlock.ai/api/v1/get/domain/all
```

### Step 3: API Documentation

View full API documentation:
- **Swagger UI**: `https://mail.inlock.ai/api/`
- Open in browser to see all available endpoints and test them interactively

---

## Available API Endpoints (Common)

Based on Mailcow API documentation, common endpoints include:

### GET Endpoints
- `/api/v1/get/status` - System status
- `/api/v1/get/system/info` - System information
- `/api/v1/get/login` - Login information
- `/api/v1/get/mailbox/all` - List all mailboxes
- `/api/v1/get/domain/all` - List all domains
- `/api/v1/get/alias/all` - List all aliases

### POST Endpoints
- `/api/v1/add/mailbox` - Add mailbox
- `/api/v1/add/domain` - Add domain
- `/api/v1/add/alias` - Add alias

### DELETE Endpoints
- `/api/v1/delete/mailbox` - Delete mailbox
- `/api/v1/delete/domain` - Delete domain

---

## Authentication Notes

- ❌ **Basic Auth (username/password)**: Does NOT work
- ✅ **API Key (X-API-Key header)**: Required method
- 🔐 **API Key Generation**: Must be done via web interface (browser login required)

---

## Scripts Created

1. **`scripts/test_mailcow_api.sh`**: Test script for API endpoints
2. **`scripts/mailcow_api_test.md`**: This documentation

---

## Next Steps

To fully test the API:

1. **Login to web interface**: `https://mail.inlock.ai/admin`
2. **Generate API key** in admin panel
3. **Use the API key** with curl or API client
4. **Test endpoints** using the Swagger UI at `https://mail.inlock.ai/api/`

---

## References

- Mailcow API Documentation: `https://mail.inlock.ai/api/`
- Mailcow Official Docs: https://docs.mailcow.email/
- Python Mailcow Library: https://github.com/derJD/python-mailcow
