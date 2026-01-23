# Claude Code Shared Configuration

Centralized agents and skills for maintaining consistency across all repositories in the organization.

## 📦 What's Included

### Agents (Autonomous Workflows)
- **fix-gh-issue-agent**: Autonomous GitHub issue resolution with branch creation and PR submission
- **review-pr-agent**: PR review, pipeline monitoring, Dependabot checks, and auto-fixing
- **commit-push-agent**: Intelligent commit and push workflow with pre-commit validation
- **code-review-validator**: Comprehensive code review against project standards and CLAUDE.md rules
- **security-deployment-validator**: Security checks, authentication validation, and deployment safety

### Skills (Quick Procedures)
- **clear-auth0-cache**: Fix "Loading Crispa" spinner issues
- **code-validation-checklist**: Complete pre-commit validation checklist
- **query-optimization-helper**: Django query optimization reference guide
- **dependabot-helper**: Manage and close outdated Dependabot PRs

## 🚀 Installation

### Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/your-org/claude-code-config/main/install.sh | bash
```

### Manual Install
```bash
# Clone into your project
git clone https://github.com/your-org/claude-code-config .claude/.shared

# Create symlinks
ln -sf ../.shared/agents/* .claude/agents/
ln -sf ../.shared/skills/* .claude/skills/
```

## 🔄 Updating

### Manual Update
```bash
cd .claude/.shared && git pull
```

### Automatic Updates (GitHub Action)
Add this workflow to `.github/workflows/update-claude-config.yml`:

```yaml
name: Update Claude Config

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Update shared config
        run: |
          cd .claude/.shared
          git pull origin main

      - name: Create PR if changes
        uses: peter-evans/create-pull-request@v5
        with:
          title: "chore: update shared Claude Code config"
          branch: update-claude-config
```

## 📝 Usage

### Using Agents
Agents are invoked automatically by Claude Code when appropriate, or you can reference them explicitly:

```bash
# Claude will automatically use agents when needed
# Example: After writing code, code-review-validator runs automatically
```

### Using Skills
Skills are reusable procedures you can reference in conversations:

```
User: "Can you run the pre-commit validation?"
Claude: [Uses code-validation-checklist skill]
```

## 🏗️ Project Structure

```
.claude/
├── .shared/              # This repo (gitignored)
│   ├── agents/
│   ├── skills/
│   └── README.md
├── agents/               # Symlinks to .shared/agents
│   ├── fix-gh-issue-agent.md → ../.shared/agents/fix-gh-issue-agent.md
│   ├── review-pr-agent.md → ../.shared/agents/review-pr-agent.md
│   └── ...
└── skills/               # Symlinks to .shared/skills
    ├── clear-auth0-cache.md → ../.shared/skills/clear-auth0-cache.md
    └── ...
```

## 🎯 Agent Descriptions

### fix-gh-issue-agent
Autonomous issue resolution workflow:
- Validates environment (git status, GitHub CLI)
- Creates semantic branches (`security/fix-xyz-123`)
- Implements complete solution
- Creates PR with `Fixes #123` linking

**Usage:**
- `fix-gh-issue --123` - Fix specific issue
- `fix-gh-issue --all` - Fix all open issues in priority order
- `fix-gh-issue --123 --review` - Step-by-step review mode

### review-pr-agent
Complete PR review and monitoring:
- Checks if Dependabot PR is outdated and closes if needed
- Updates base branch if behind
- Monitors CI/CD checks with real-time status
- Auto-fixes pipeline failures (with --auto-approve flag)
- Auto-approves and merges when all checks pass

**Usage:**
- `review-pr --123` - Monitor PR checks
- `review-pr --123 --auto-approve` - Auto-fix, approve, and merge
- `review-pr --123 --no-update` - Skip base branch update

### commit-push-agent
Intelligent commit workflow:
- Runs mandatory pre-commit validation
- Auto-generates conventional commit messages
- Creates feature branches if on protected branches
- Pushes with upstream tracking

**Usage:**
- `commit-push` - Auto commit and push
- `commit-push --message "fix: bug"` - Custom message

### code-review-validator
Comprehensive code review:
- Validates against all CLAUDE.md rules
- Detects anti-patterns (N+1 queries, security issues)
- Checks for code redundancies
- Ensures architecture consistency

**Triggered automatically after code changes**

### security-deployment-validator
Security and deployment safety:
- Scans for secrets, hardcoded IDs, API keys
- Validates tenant page authentication
- Checks branch protection rules
- Ensures environment variables have no defaults

**Triggered before commits and deployments**

## 🛠️ Skills Descriptions

### clear-auth0-cache
Quick fix for "Loading Crispa" spinner issues:
```javascript
localStorage.clear();
sessionStorage.clear();
location.reload();
```

### code-validation-checklist
Complete pre-commit validation checklist covering:
- 🔒 Security (secrets, hardcoded IDs)
- 📝 Code Quality (console.log, TypeScript any)
- 🌍 Localization (hardcoded locales/currencies)
- ⚡ Performance (N+1 queries)
- 🔐 Authentication (tenant page auth)
- 🚫 Environment Variables (no defaults)

### query-optimization-helper
Django ORM optimization guide:
- When to use `select_related()` vs `prefetch_related()`
- Common N+1 query patterns
- Performance best practices

### dependabot-helper
Manage Dependabot PRs:
- Check if upgrade is already satisfied
- Parse package versions from lock files
- Close outdated PRs with explanation

## 🔧 Customization

### Repo-Specific Agents
Keep shared agents via symlinks, add custom ones directly:

```bash
# Shared agent (symlink)
.claude/agents/fix-gh-issue-agent.md → ../.shared/agents/fix-gh-issue-agent.md

# Custom agent (direct file)
.claude/agents/custom-project-agent.md
```

### Override Shared Configs
To override a shared agent/skill, remove the symlink and create your own file:

```bash
rm .claude/agents/code-review-validator.md
# Create custom version
vim .claude/agents/code-review-validator.md
```

## 🤝 Contributing

### Making Changes
1. Clone this repo
2. Create feature branch
3. Make changes to agents/skills
4. Test in a project repo
5. Submit PR

### Testing Changes
```bash
# In a test project
cd .claude/.shared
git checkout your-feature-branch
git pull

# Test the changes
# Then switch back
git checkout main
```

## 📋 Version History

### v1.0.0 (2024-01-23)
- Initial release
- 5 agents, 4 skills
- Installation script
- Auto-update GitHub Action

## 🐛 Issues & Feedback

Report issues at: https://github.com/your-org/claude-code-config/issues

## 📄 License

MIT License - See LICENSE file for details
