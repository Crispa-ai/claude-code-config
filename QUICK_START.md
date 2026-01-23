# Quick Start Guide

## What You Have

✅ **5 Agents** - Autonomous workflows for complex tasks
✅ **4 Skills** - Quick procedures for common issues
✅ **Installation Script** - One-command setup for any repo
✅ **Auto-Update Action** - Weekly PR with latest changes
✅ **Complete Documentation** - README, SETUP, and this guide

---

## Create GitHub Repository (5 minutes)

### Step 1: Navigate to shared directory

```bash
cd /Users/avise/Desktop/work/monorepo/.claude-shared
```

### Step 2: Initialize git repository

```bash
# Initialize git
git init
git branch -M main

# Add all files
git add .

# Create initial commit
git commit -m "feat: initial Claude Code shared configuration

- 5 agents: fix-gh-issue, review-pr, commit-push, code-review-validator, security-deployment-validator
- 4 skills: clear-auth0-cache, code-validation-checklist, query-optimization-helper, dependabot-helper
- Installation script with symlink support
- GitHub Action for automatic updates
- Comprehensive documentation

Agents handle autonomous workflows:
- GitHub issue resolution with branch creation and PRs
- PR review with pipeline monitoring and auto-fixing
- Smart commit workflow with mandatory validation
- Code review against CLAUDE.md standards
- Security and deployment safety checks

Skills provide quick procedures:
- Auth0 cache clearing for loading spinner issues
- Complete pre-commit validation checklist
- Django query optimization reference
- Dependabot PR management and outdated check"

# Verify commit
git log --oneline
```

### Step 3: Create GitHub repository

**Option A: Using GitHub CLI (recommended)**

```bash
# Create public repository in your organization
gh repo create crispa-org/claude-code-config \
  --public \
  --description "Shared Claude Code agents and skills for Crispa projects" \
  --source=. \
  --remote=origin \
  --push
```

**Option B: Using GitHub Web UI**

1. Go to https://github.com/organizations/crispa-org/repositories/new
2. Repository name: `claude-code-config`
3. Description: "Shared Claude Code agents and skills for Crispa projects"
4. Public repository
5. Do NOT initialize with README, .gitignore, or license (we already have them)
6. Click "Create repository"

Then push:
```bash
git remote add origin git@github.com:crispa-org/claude-code-config.git
git push -u origin main
```

### Step 4: Verify repository

```bash
# View repository in browser
gh repo view crispa-org/claude-code-config --web

# Or verify files via CLI
gh api repos/crispa-org/claude-code-config/contents | jq -r '.[].name'
```

---

## Install in Monorepo (2 minutes)

### Step 1: Navigate to monorepo root

```bash
cd /Users/avise/Desktop/work/monorepo
```

### Step 2: Run installation

```bash
# Install shared configuration
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash
```

### Step 3: Verify installation

```bash
# Check symlinks were created
ls -la .claude/agents/
ls -la .claude/skills/

# Verify symlink targets
readlink .claude/agents/fix-gh-issue-agent.md
# Should output: ../.shared/agents/fix-gh-issue-agent.md
```

### Step 4: Commit changes

```bash
# Add symlinks and updated .gitignore
git add .claude/agents/ .claude/skills/ .gitignore

# Commit
git commit -m "chore: install shared Claude Code configuration

Installed from crispa-org/claude-code-config:
- 5 agents via symlinks
- 4 skills via symlinks
- .shared/ directory added to .gitignore

Agents and skills are now centrally managed and can be updated automatically."

# Push
git push origin optimize-banking-transaction-sync
```

---

## Test the Agents (5 minutes)

### Test 1: Code Validation Skill

```bash
# Make a small change
echo "// test" >> frontend/src/test.ts

# Stage it
git add frontend/src/test.ts

# Test validation (this is what commit-push agent uses)
bash .claude/skills/code-validation-checklist.md
# Wait, skills are markdown, not scripts. Let me check if there's a script section...
```

Actually, skills are documentation. To test agents, use Claude Code directly:

### Test 2: Use commit-push Agent

```bash
# In Claude Code session
commit-push --message "test: verify shared config installation"
# Claude will run the validation automatically
```

### Test 3: Check Agent Files

```bash
# Verify agents are readable
cat .claude/agents/fix-gh-issue-agent.md | head -20

# Count lines in each agent
wc -l .claude/agents/*.md
```

---

## Install in Other Repositories

For each additional repository:

```bash
# Navigate to repository
cd /path/to/other-repo

# Install
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash

# Commit
git add .claude/agents/ .claude/skills/ .gitignore
git commit -m "chore: install shared Claude Code configuration"
git push
```

---

## Enable Auto-Updates

### Add GitHub Action to Each Repository

```bash
# In each repository
mkdir -p .github/workflows

# Copy the workflow
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/.github/workflows/update-claude-config.yml \
  -o .github/workflows/update-claude-config.yml

# Commit
git add .github/workflows/update-claude-config.yml
git commit -m "chore: add auto-update workflow for Claude Code config"
git push
```

### Manual Trigger

```bash
# Trigger update immediately (via GitHub CLI)
gh workflow run update-claude-config.yml

# Or via GitHub UI:
# Go to Actions → Update Claude Config → Run workflow
```

---

## Update Shared Config

When you need to update agents or skills:

```bash
# Navigate to shared config repo
cd /path/to/claude-code-config

# Make changes
vim agents/fix-gh-issue-agent.md

# Commit and push
git add .
git commit -m "feat: improve error handling in fix-gh-issue agent"
git push origin main
```

All repositories with auto-update enabled will receive a PR on the next Sunday (or trigger manually).

---

## Project Checklist

### Immediate Tasks (Today)
- [ ] Create GitHub repository: `crispa-org/claude-code-config`
- [ ] Push `.claude-shared/` contents to new repository
- [ ] Install in monorepo
- [ ] Test agents work correctly
- [ ] Commit CLAUDE.md changes to monorepo

### Short-term Tasks (This Week)
- [ ] Install in other repositories (list below)
- [ ] Add auto-update GitHub Action to all repos
- [ ] Document in team wiki/Notion
- [ ] Demo to team members

### Repositories to Install In
- [ ] monorepo (this one)
- [ ] [List other repos here]

---

## Verification Commands

```bash
# Check repository exists
gh repo view crispa-org/claude-code-config

# Check installation in a repo
ls -la .claude/agents/
ls -la .claude/skills/

# Check symlinks are correct
readlink .claude/agents/fix-gh-issue-agent.md

# Check .shared directory is gitignored
git check-ignore .claude/.shared/

# View agent content
cat .claude/agents/fix-gh-issue-agent.md | less

# Count total lines of configuration
find .claude/.shared -name "*.md" -exec wc -l {} + | tail -1
```

---

## File Size Summary

```
Total Configuration:
- Agents: ~3,000 lines
- Skills: ~1,500 lines
- Documentation: ~500 lines
Total: ~5,000 lines of reusable configuration

CLAUDE.md Reduction:
- Before: 1,396 lines
- After: ~600 lines
- Reduction: 57% smaller
```

---

## Success Criteria

✅ Repository created at `github.com/crispa-org/claude-code-config`
✅ All files pushed to repository
✅ Installation works via curl command
✅ Symlinks created correctly in target repos
✅ Agents accessible to Claude Code
✅ CLAUDE.md reduced and maintainable
✅ Auto-update workflow ready to deploy

---

## Getting Help

- **Installation Issues**: Check SETUP.md
- **Agent Customization**: See README.md
- **Bug Reports**: https://github.com/crispa-org/claude-code-config/issues
- **Questions**: Ask in team Slack

---

## What's Next?

After setup is complete:

1. **Use the Agents**: Claude Code will automatically use agents when appropriate
2. **Reference Skills**: Ask Claude to run specific validations or checks
3. **Iterate and Improve**: Update agents based on team feedback
4. **Share Improvements**: Push updates benefit everyone
5. **Monitor Usage**: Track which agents/skills are most valuable

---

You're ready to go! 🚀

Start with creating the GitHub repository, then install in the monorepo to test.
