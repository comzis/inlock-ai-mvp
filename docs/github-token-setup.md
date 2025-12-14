# Using GitHub Personal Access Token

## Step 1: Create Personal Access Token

1. Go to: https://github.com/settings/tokens/new
2. Token name: "inlock-ai-mvp-server"
3. Expiration: Choose your preference (90 days, 1 year, or no expiration)
4. Select scopes:
   - ✅ **repo** (Full control of private repositories)
     - This includes: repo:status, repo_deployment, public_repo, repo:invite, security_events
5. Click **"Generate token"**
6. **IMPORTANT**: Copy the token immediately - you won't see it again!
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Use Token for Push

### Option A: Use token in URL (one-time)
```bash
cd /home/comzis/inlock-infra
git remote set-url origin https://YOUR_TOKEN@github.com/comzis/inlock-ai-mvp.git
git push -u origin main
```

### Option B: Use token when prompted
```bash
cd /home/comzis/inlock-infra
git push -u origin main
# Username: your_github_username
# Password: paste_your_token_here (not your GitHub password!)
```

### Option C: Store credentials securely
```bash
cd /home/comzis/inlock-infra
git config credential.helper store
git push -u origin main
# Enter username and token once - they'll be saved in ~/.git-credentials
```

## Step 3: Verify
After pushing, check:
- https://github.com/comzis/inlock-ai-mvp

## Security Note
Tokens are like passwords - keep them secure!
- Don't commit tokens to git
- Don't share tokens publicly
- Revoke old tokens if compromised
