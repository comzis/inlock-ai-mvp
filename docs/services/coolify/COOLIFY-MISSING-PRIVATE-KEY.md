# Coolify: Missing Private Key Error

**Error:** `No query results for model [App\Models\PrivateKey] 0`

This means the server configuration doesn't have an SSH private key selected.

---

## Solution: Add Private Key

You need to add the SSH private key to Coolify first, then select it in the server configuration.

### Step 1: Add Private Key to Coolify

1. **Go to the "Private Key" tab** in the server configuration (or Settings → SSH Keys)
2. **Click "Add Private Key"** or similar button
3. **Enter the key details:**
   - **Name:** `deploy-inlock-ai-key` (or `inlock-ai-infrastructure`)
   - **Private Key:** Paste your private key content

### Step 2: Get Your Private Key

On your server, get the private key:

```bash
cat /home/comzis/.ssh/keys/deploy-inlock-ai-key
```

Copy the entire output (starts with `-----BEGIN OPENSSH PRIVATE KEY-----` or `-----BEGIN RSA PRIVATE KEY-----`)

### Step 3: Add Key to Coolify

1. In Coolify UI, go to **Settings** → **SSH Keys** (or the Private Key section)
2. Click **"Add SSH Key"** or **"New Private Key"**
3. **Name:** `deploy-inlock-ai-key`
4. **Private Key:** Paste the key content (entire key including BEGIN/END lines)
5. **Save**

### Step 4: Select Key in Server Configuration

1. Go back to **Server** → **Configuration** → **General**
2. Find the **"Private Key"** field/dropdown
3. **Select** the key you just added (`deploy-inlock-ai-key`)
4. **Save** the server configuration
5. **Click "Validate Server"** again

---

## Alternative: Check Private Key Tab

The server configuration page should have a **"Private Key"** tab in the left sidebar (next to Configuration, Proxy, Resources, Terminal, Security).

1. Click on **"Private Key"** tab
2. **Select** an existing key OR **add a new one**
3. Save
4. Go back to **"General"** tab and validate again

---

## Key Format

The private key should look like:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn
...
(many lines)
...
-----END OPENSSH PRIVATE KEY-----
```

**Important:** Include the BEGIN and END lines.

---

## Verification

After adding the key and selecting it:
- Go to **General** tab
- Click **"Validate Server"**
- Should succeed! ✅

---

**The key is the same `deploy-inlock-ai-key` we've been using - you just need to add it to Coolify's key management system.**

