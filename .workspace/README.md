# Antigravity Workspace Artifacts

This directory contains Antigravity conversation artifacts and planning documents.

## Files

- `task.md` - Task breakdown and checklist
- `implementation_plan.md` - Project reorganization plan
- `walkthrough.md` - Complete work summary
- `todo-analysis.md` - TODO consolidation and analysis
- `ANTIGRAVITY-TASK-PROMPT.md` - Standardized prompt template for Antigravity AI
- `ANTIGRAVITY-QUICK-START.md` - Quick reference guide for Antigravity tasks

## Usage

**On Server (Primary Work):**
- Work here via SSH
- Artifacts in `/home/comzis/.gemini/antigravity/brain/`
- Sync changes to Git

**On MacBook (Reference):**
- Clone repo: `git clone https://github.com/comzis/inlock-ai-mvp.git`
- Open `.workspace/` in Antigravity app
- Pull updates: `git pull origin main`

## Workflow

1. **Start Task**: Use `ANTIGRAVITY-TASK-PROMPT.md` template for structured task execution
2. **Quick Reference**: Use `ANTIGRAVITY-QUICK-START.md` for common tasks
3. **Work on server via SSH**: Follow Git workflow (`docs/GIT-WORKFLOW.md`)
4. **Changes auto-saved to Antigravity workspace**
5. **Periodically copy to `.workspace/` and push**:
   ```bash
   cp ~/.gemini/antigravity/brain/<id>/*.md /home/comzis/inlock/.workspace/
   git add .workspace/
   git commit -m "docs: Update workspace artifacts"
   git push origin [branch-name]
   ```
6. **On MacBook**: `git pull` to get latest

## Using Antigravity Task Prompts

### For New Tasks

1. Open `ANTIGRAVITY-TASK-PROMPT.md` template
2. Fill in task details (description, branch type, commit type)
3. Provide to Antigravity with project context
4. Antigravity will follow Git workflow and contributing guidelines

### Quick Tasks

Use `ANTIGRAVITY-QUICK-START.md` for:
- Feature development
- Bug fixes
- Documentation updates
- Common workflows

### Reference Documentation

- **Git Workflow**: `../docs/GIT-WORKFLOW.md`
- **Contributing Guidelines**: `../CONTRIBUTING.md`
- **Task Prompt Template**: `ANTIGRAVITY-TASK-PROMPT.md`
- **Quick Start**: `ANTIGRAVITY-QUICK-START.md`

---
*Conversation ID: 0c7c2b4d-3034-4ed3-8ed7-d9edcf16f9b6*
