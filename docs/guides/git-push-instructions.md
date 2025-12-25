# Git Push Instructions for inlock-ai-mvp

## Current Status
✅ All changes committed locally
✅ Remote configured: https://github.com/comzis/inlock-ai-mvp.git
✅ Branch: main
✅ Commits ready: 2 commits

## Steps to Push

### 1. Create Repository on GitHub
- Go to: https://github.com/new
- Repository name: `inlock-ai-mvp`
- Visibility: Private or Public (your choice)
- **Do NOT** initialize with README, .gitignore, or license
- Click "Create repository"

### 2. Configure Authentication

#### Option A: Personal Access Token (HTTPS - Recommended)
1. Create token: https://github.com/settings/tokens/new
   - Name: "inlock-ai-mvp"
   - Scopes: Select `repo` (full control)
   - Generate token
   - Copy the token (you won't see it again!)

2. Push with token:
   ```bash
   cd /home/comzis/inlock-infra
   git push -u origin main
   # Username: your_github_username
   # Password: paste_your_token_here
   ```

#### Option B: SSH Key
1. Generate SSH key (if needed):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   cat ~/.ssh/id_ed25519.pub
   ```

2. Add to GitHub: https://github.com/settings/keys
   - Click "New SSH key"
   - Paste your public key

3. Update remote and push:
   ```bash
   cd /home/comzis/inlock-infra
   git remote set-url origin git@github.com:comzis/inlock-ai-mvp.git
   git push -u origin main
   ```

#### Option C: Store Credentials (One-time)
```bash
git config --global credential.helper store
git push -u origin main
# Enter username and token once - they'll be saved
```

### 3. Verify Push
```bash
git log --oneline
git remote -v
git branch -r  # Should show origin/main
```

## Commits to Push
- eaea590 Initial commit: Inlock Infrastructure
- 7ba535e Complete Inlock AI deployment: rebranding, monitoring, automation
