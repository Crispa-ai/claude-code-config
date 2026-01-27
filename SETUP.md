# Setup Guide for Claude Code Shared Configuration

## What Was Created

This directory (`.claude-shared/`) contains a complete package for sharing Claude Code agents and skills across all Crispa repositories.

### Directory Structure

```
.claude-shared/
├── README.md                    # Main documentation
├── LICENSE                      # MIT License
├── SETUP.md                    # This file
├── install.sh                  # Installation script
├── .github/
│   └── workflows/
│       └── update-claude-config.yml  # Auto-update GitHub Action
├── agents/                     # Autonomous workflow agents
│   ├── fix-gh-issue-agent.md
│   ├── review-pr-agent.md
│   ├── commit-push-agent.md
│   ├── code-review-validator.md
│   └── security-deployment-validator.md
└── skills/                     # Quick procedure skills
    ├── clear-auth0-cache.md
    ├── code-validation-checklist.md
    ├── query-optimization-helper.md
    └── dependabot-helper.md
```

### What Changed in CLAUDE.md

The main `CLAUDE.md` file has been condensed from **1,396 lines to ~600 lines**:

- ✅ **Kept**: High-level command descriptions, critical rules, anti-patterns, project overview
- ❌ **Removed**: Detailed implementation steps (now in agents)
- ❌ **Removed**: Lengthy validation scripts (now in skills)
- ✅ **Added**: References to agents and skills for detailed guidance

**Backup**: Original CLAUDE.md saved as `CLAUDE.md.backup`

---

## Next Steps

### 1. Create GitHub Repository

Create a new repository in your organization:

```bash
# Create repository (replace 'crispa-org' with your org name)
gh repo create crispa-org/claude-code-config --public --description "Shared Claude Code agents and skills for Crispa projects"

# Navigate to the shared config directory
cd .claude-shared

# Initialize git if not already done
git init
git branch -M main

# Add all files
git add .

# Create initial commit
git commit -m "feat: initial Claude Code shared configuration

- 5 agents for autonomous workflows
- 4 skills for quick procedures
- Installation script with symlink support
- GitHub Action for automatic updates
- Comprehensive documentation"

# Push to remote
git remote add origin git@github.com:crispa-org/claude-code-config.git
git push -u origin main
```

### 2. Test Installation in This Repo

Test the installation in the current monorepo:

```bash
# Navigate to repository root
cd /Users/avise/Desktop/work/monorepo

# Backup existing .claude directory (if you want to preserve custom configs)
cp -r .claude .claude.backup

# Run installation
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash

# Or test locally before pushing to GitHub
bash .claude-shared/install.sh

# Verify symlinks were created
ls -la .claude/agents/
ls -la .claude/skills/

# Test an agent
# (Claude will automatically use agents when appropriate)
```

### 3. Update CLAUDE.md References

Update the repository URL in CLAUDE.md:

1. Open `CLAUDE.md`
2. Find: `curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh`
3. Replace `crispa-org` with your actual organization name

### 4. Install in Other Repositories

For each repository in your organization:

```bash
cd path/to/other-repo

# Install shared config
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash

# Commit the symlinks
git add .claude/agents .claude/skills .gitignore
git commit -m "chore: install shared Claude Code configuration"
git push
```

### 5. Set Up Auto-Updates (Optional)

Add the GitHub Action to automatically update shared config:

```bash
# In each repository
mkdir -p .github/workflows

# Copy the workflow file
cp .claude/.shared/.github/workflows/update-claude-config.yml .github/workflows/

# Commit
git add .github/workflows/update-claude-config.yml
git commit -m "chore: add auto-update workflow for Claude Code config"
git push
```

The workflow will:
- Run every Sunday at midnight UTC
- Create a PR when updates are available
- Can be triggered manually via GitHub Actions UI

---

## Customization

### Repo-Specific Agents/Skills

Keep shared configs via symlinks, add custom ones directly:

```bash
# Shared agent (symlink)
.claude/agents/fix-gh-issue-agent.md → ../.shared/agents/fix-gh-issue-agent.md

# Custom agent (direct file)
.claude/agents/custom-project-agent.md
```

### Override Shared Config

To override a shared agent/skill in a specific repo:

```bash
# Remove symlink
rm .claude/agents/code-review-validator.md

# Create custom version
vim .claude/agents/code-review-validator.md
```

---

## Maintenance

### Updating Shared Config

Make changes to agents/skills in the `claude-code-config` repository:

```bash
cd /path/to/claude-code-config

# Edit agents or skills
vim agents/fix-gh-issue-agent.md

# Commit and push
git add .
git commit -m "feat: improve fix-gh-issue agent with better error handling"
git push origin main
```

All repositories with auto-update enabled will receive a PR with the changes on the next Sunday (or trigger manually).

### Manual Update in a Repository

```bash
cd /path/to/your-repo
cd .claude/.shared
git pull origin main
```

---

## Migration Checklist

- [ ] Create `crispa-org/claude-code-config` GitHub repository
- [ ] Push `.claude-shared/` contents to new repository
- [ ] Update repository URL in CLAUDE.md
- [ ] Test installation in current monorepo
- [ ] Verify agents work as expected
- [ ] Install in other repositories (list them below)
- [ ] Set up auto-update GitHub Action in all repos
- [ ] Document shared config in team wiki/docs
- [ ] Train team on new workflow

### Repositories to Install In

- [ ] monorepo (this repo)
- [ ] [add other repo names here]
- [ ] [add other repo names here]

---

## Troubleshooting

### Symlinks Not Working

If symlinks aren't created correctly:

```bash
# Check if symlinks exist
ls -la .claude/agents/

# Manually create symlink
ln -s ../.shared/agents/fix-gh-issue-agent.md .claude/agents/fix-gh-issue-agent.md
```

### Agent Not Found

If Claude Code doesn't recognize an agent:

```bash
# Verify agent file exists
cat .claude/agents/fix-gh-issue-agent.md

# Check symlink target
readlink .claude/agents/fix-gh-issue-agent.md

# Should output: ../.shared/agents/fix-gh-issue-agent.md
```

### Updates Not Pulled

If auto-update PR isn't created:

```bash
# Manually trigger GitHub Action via GitHub UI
# Or run update manually:
cd .claude/.shared
git pull origin main
```

---

## Benefits

✅ **Consistency**: Same agents and skills across all repositories
✅ **Maintainability**: Update once, deploy everywhere
✅ **Version Control**: Track changes to workflows over time
✅ **Easy Onboarding**: New repositories get best practices immediately
✅ **Collaboration**: Share improvements across the organization

---

---

## Notion Documentation Automation

Automatically generate feature documentation from PRs and upload to Notion.

### Prerequisites

1. **Notion Integration**
   - Create at [notion.so/my-integrations](https://notion.so/my-integrations)
   - Copy the "Internal Integration Token"

2. **Notion Teamspace Structure**

   Create this folder hierarchy in your teamspace:

   ```text
   📁 Engineering
   └── 📁 Feature Documentation
       ├── 📊 Feature Docs Database    ← Your database here
       ├── 📁 2025-Q1
       ├── 📁 2025-Q2
       └── ...
   ```

3. **Notion Database Properties**

   Create a database with these properties:

   | Property    | Type      | Notes                                 |
   | ----------- | --------- | ------------------------------------- |
   | Name        | Title     | Page title (required)                 |
   | Status      | Select    | Options: Draft, Published, Archived   |
   | Environment | Select    | Options: Staging, Production          |
   | Category    | Select    | Options: Feature, Bugfix, Refactor    |
   | PR Link     | URL       | Link to GitHub PR                     |
   | Author      | Rich Text | PR author username                    |
   | Date        | Date      | Generation date                       |
   | Quarter     | Select    | Options: Q1, Q2, Q3, Q4               |

4. **Share Database with Integration**

   - Open your database in Notion
   - Click "..." menu → Connections → Add your integration

5. **Get Database ID**

   From the database URL:

   ```text
   https://notion.so/your-workspace/abc123def456...?v=...
                                     ↑ Database ID (32 hex chars)
   ```

### GitHub Secrets

Add these secrets to your repository (Settings → Secrets → Actions):

| Secret               | Description                                  |
| -------------------- | -------------------------------------------- |
| `ANTHROPIC_API_KEY`  | Claude API key (used by Claude Code CLI)     |
| `NOTION_API_KEY`     | Notion integration token                     |
| `NOTION_DATABASE_ID` | Target database ID                           |

### Workflow Trigger

The workflow triggers on:

- PRs opened to `staging` or `production` branches
- PRs marked "ready for review"

It skips:

- Draft PRs
- Dependabot PRs

### Generated Documentation

Each page includes:

- Feature overview
- Problem solved
- Technical implementation
- API/database changes
- Configuration changes
- Usage examples
- Testing notes
- Migration notes

---

## Questions?

- **Documentation**: See `README.md` in this directory
- **Issues**: Report at <https://github.com/Crispa-ai/claude-code-config/issues>
- **Updates**: Check GitHub releases for version history

Happy coding with Claude!
