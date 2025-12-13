# Auth0 Dashboard - Where to Find Callback URL Setting

**Important:** There are TWO different settings you need to check!

---

## ✅ What You Found (CORRECT!)

**Location:** Cross-Origin Authentication → Allowed Origins (CORS)  
**Current Value:** `https://auth.inlock.ai`  
**Status:** ✅ **CORRECT** - This matches what we need!

---

## ❓ What You Still Need to Check

**Location:** Application Settings (main settings page)  
**Field Name:** "Allowed Callback URLs"  
**Expected Value:** `https://auth.inlock.ai/oauth2/callback`

---

## How to Find the Callback URL Field

### Step 1: You're Currently On...
- **Page:** Cross-Origin Authentication settings
- **What You See:** "Allowed Origins (CORS)" = `https://auth.inlock.ai` ✅

### Step 2: Go to Application Settings

1. **Look for:** Breadcrumb navigation or left sidebar
2. **Click:** "Settings" (or "Application Settings")
   - This should take you to the main application settings page
3. **Scroll down** to find the "Application URIs" section

### Step 3: Find "Allowed Callback URLs"

On the Application Settings page, look for:

**Section:** "Application URIs" (or similar)  
**Field:** "Allowed Callback URLs"  
**Expected Value:** Should contain:
```
https://auth.inlock.ai/oauth2/callback
```

**Note:** This is different from "Allowed Origins (CORS)" which you already verified.

---

## Quick Reference

| Setting | Location | Current Value | Expected Value | Status |
|---------|----------|---------------|----------------|--------|
| **Allowed Origins (CORS)** | Cross-Origin Authentication | `https://auth.inlock.ai` | `https://auth.inlock.ai` | ✅ CORRECT |
| **Allowed Callback URLs** | Application Settings | [Need to check] | `https://auth.inlock.ai/oauth2/callback` | ⏳ PENDING |

---

## What You've Verified So Far

✅ **Allowed Origins (CORS):** `https://auth.inlock.ai` - **CORRECT**

---

## Next Step

1. Navigate to the main **Application Settings** page
2. Find the **"Allowed Callback URLs"** field
3. Verify it contains: `https://auth.inlock.ai/oauth2/callback`
4. Take screenshot if different or missing

---

**Tip:** If you can't find the "Allowed Callback URLs" field, look for:
- "Application URIs"
- "Redirect URIs"
- "Callback URLs"
- Or scroll through the entire Settings page

