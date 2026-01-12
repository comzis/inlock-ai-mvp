# Antigravity Git Branch Workflow

**Working with Git Branches in Antigravity Remote Connections**

---

## Remote Connection Format

**Base command** (Format 1 - confirmed working):
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

---

## Loading Specific Git Branch

Antigravity doesn't directly support branch specification in the `--remote` command. Instead, you need to:

### Option 1: Switch Branch Before Connecting (Recommended)

**Step 1**: SSH to server and checkout the branch:
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout <branch-name> && git pull"
```

**Step 2**: Then connect with Antigravity:
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

**Example for test branch**:
```bash
# Switch to test branch first
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout antigravity/test-features && git pull"

# Then connect
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

### Option 2: Create Helper Script

Create a script that switches branch and connects:

**On Mac** (`~/antigravity-branch.sh`):
```bash
#!/bin/bash
BRANCH=$1
REMOTE_PATH="/home/comzis/projects/inlock-ai-mvp"

if [ -z "$BRANCH" ]; then
    echo "Usage: $0 <branch-name>"
    exit 1
fi

# Switch to branch on remote
echo "Switching to branch: $BRANCH"
ssh comzis@100.83.222.69 "cd $REMOTE_PATH && git checkout $BRANCH && git pull"

# Connect with Antigravity
echo "Connecting Antigravity to $BRANCH branch..."
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69$REMOTE_PATH
```

**Usage**:
```bash
chmod +x ~/antigravity-branch.sh
~/antigravity-branch.sh antigravity/test-features
```

### Option 3: Use Git Worktree (Advanced)

Create a separate worktree for each branch:

**On remote server**:
```bash
cd /home/comzis/projects
git worktree add -b <branch-name> inlock-ai-mvp-<branch-name> <branch-name>
```

**Connect to worktree**:
```bash
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp-<branch-name>
```

---

## Common Workflows

### Development on Feature Branch

```bash
# 1. Switch to feature branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout feature/my-feature && git pull"

# 2. Connect Antigravity
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp

# 3. Work with Antigravity on the branch

# 4. Commit changes (via git commands on server)
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git add . && git commit -m 'Changes'"
```

### Testing on Antigravity Test Branch

```bash
# Switch to test branch
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout antigravity/test-features && git pull"

# Connect Antigravity
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

### Working on Main Branch

```bash
# Switch to main
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git checkout main && git pull"

# Connect Antigravity
/Users/comzis/.antigravity/antigravity/bin/antigravity --remote ssh://comzis@100.83.222.69/home/comzis/projects/inlock-ai-mvp
```

---

## Available Branches

Check available branches:
```bash
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git branch -a"
```

Common branches in this project:
- `main` - Main development branch
- `antigravity/test-features` - Antigravity test branch
- `feature/*` - Feature branches
- `security/*` - Security branches

---

## Notes

- **Antigravity always connects to the current checked-out branch** on the remote server
- You must switch branches on the remote server before connecting
- Use `git pull` to ensure branch is up to date
- Changes made by Antigravity will be on the current branch
- Commit changes via SSH or after disconnecting

---

## Verification

After switching branch, verify:
```bash
# Check current branch on remote
ssh comzis@100.83.222.69 "cd /home/comzis/projects/inlock-ai-mvp && git branch --show-current"
```

Then connect with Antigravity - it will open the branch you just checked out.
