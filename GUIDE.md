# Claude Code Configuration Guide

Complete installation and usage guide for the shared Claude Code agents and skills.

---

## Table of Contents

- [Installation](#installation)
- [Agents Overview](#agents-overview)
- [Skills Overview](#skills-overview)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Quick Install (Recommended)

Run this command in any repository root:

```bash
curl -fsSL https://raw.githubusercontent.com/Crispa-ai/claude-code-config/main/install.sh | bash
```

**What it does:**
1. Clones the config repo to `~/.claude-code-config` (global cache)
2. Creates a symlink `.claude-shared/` → `~/.claude-code-config`
3. Adds `.claude-shared/` to `.gitignore` if needed

### Manual Install

```bash
# Clone to home directory
git clone https://github.com/Crispa-ai/claude-code-config.git ~/.claude-code-config

# Create symlink in your project
ln -sf ~/.claude-code-config .claude-shared

# Add to gitignore
echo ".claude-shared" >> .gitignore
```

### Verify Installation

```bash
# Check symlink exists
ls -la .claude-shared/

# Should show:
# .claude-shared -> /Users/you/.claude-code-config

# Check agents are accessible
ls .claude-shared/agents/

# Check skills are accessible
ls .claude-shared/skills/
```

### Update to Latest

```bash
cd ~/.claude-code-config && git pull
```

Or re-run the install script:

```bash
curl -fsSL https://raw.githubusercontent.com/Crispa-ai/claude-code-config/main/install.sh | bash
```

---

## Agents Overview

Agents are autonomous workflows that handle complex, multi-step tasks. Claude Code automatically discovers and uses these agents.

### 1. fix-gh-issue-agent

**Purpose:** Autonomous GitHub issue resolution from open to closed.

**Color:** 🟢 Green

**What it does:**
- Validates environment (git status, GitHub CLI auth)
- Creates semantic branch names (`security/fix-xyz-123`, `bugfix/resolve-login-456`)
- Implements complete solution following project conventions
- Runs tests and security scans
- Creates PR with proper `Fixes #123` linking

**Commands:**
```bash
fix-gh-issue --123           # Fix specific issue #123
fix-gh-issue --all           # Fix all open issues in priority order
fix-gh-issue --123 --review  # Step-by-step review mode
```

**Priority order for `--all`:**
1. Security issues (labels containing "security")
2. Bugs (labels containing "bug", "critical")
3. Features (labels containing "feature", "enhancement")

---

### 2. review-pr-agent

**Purpose:** PR review, pipeline monitoring, and auto-fixing.

**Color:** 🔵 Blue

**What it does:**
- Checks if Dependabot PR is outdated (closes if already satisfied)
- Updates base branch if PR is behind
- Monitors CI/CD checks with real-time status updates
- Analyzes and auto-fixes pipeline failures
- Auto-approves and merges when all checks pass

**Commands:**
```bash
review-pr --123                # Monitor PR checks only
review-pr --123 --auto-approve # Auto-fix, approve, and merge
review-pr --123 --auto-fix     # Fix failures, don't approve
review-pr --123 --no-update    # Skip base branch update
```

**Auto-fixable issues:**
- Linting/formatting (ESLint, Prettier, Black, Ruff)
- Simple type errors
- Outdated snapshots
- Missing imports

---

### 3. commit-push-agent

**Purpose:** Intelligent commit workflow with mandatory validation.

**Color:** 🟡 Yellow

**What it does:**
- Runs complete CLAUDE.md validation before committing
- Auto-generates conventional commit messages
- Creates feature branches if on protected branches
- Pushes with upstream tracking

**Commands:**
```bash
commit-push                              # Auto-generate message
commit-push --message "feat: add login"  # Custom message
```

**Validation checks:**
1. Secrets/tokens in code
2. Hardcoded IDs
3. `console.log` statements
4. TypeScript `any` usage
5. Hardcoded locales (`da-DK`, `DKK`)
6. Environment variable defaults
7. TODO error handling
8. Branch protection
9. Tenant page authentication

---

### 4. code-review-validator

**Purpose:** Comprehensive code review against project standards.

**Color:** 🟣 Purple

**What it does:**
- Validates code against all CLAUDE.md rules
- Detects anti-patterns (N+1 queries, security issues)
- Checks for code redundancies and inconsistencies
- Ensures architecture consistency
- Verifies Django/React best practices

**When triggered:**
- After significant code changes
- When new files are created
- After model/serializer modifications
- After error handling updates

**Review areas:**
- Security vulnerabilities
- Performance issues (N+1 queries)
- Type safety
- Error handling completeness
- Authentication coverage
- Transaction usage

---

### 5. security-deployment-validator

**Purpose:** Security checks and deployment safety validation.

**Color:** 🔴 Red

**What it does:**
- Scans for secrets, tokens, API keys in code
- Detects hardcoded IDs (user, tenant, Slack)
- Validates webhook verification (not `return True`)
- Checks tenant page authentication
- Validates branch protection compliance
- Ensures no environment variable defaults

**When to use:**
- Before committing sensitive changes
- Before deploying to staging/production
- When reviewing auth/webhook code
- After security-related features

**Critical checks:**
- No secrets in code → STOP deployment
- Webhook `return True` → CRITICAL vulnerability
- Missing page auth → Security breach risk
- Direct commits to protected branches → Block

---

### 6. full-stack-dev-agent

**Purpose:** Complete development workflow for Django + Next.js.

**Color:** 🟣 Purple

**What it does:**
- Runs backend tests (pytest) and frontend tests (Jest)
- Creates and applies Django migrations
- Seeds database with demo data
- Updates dependencies
- Runs builds and linting
- Generates boilerplate code

**Common tasks:**
```bash
# Run all tests
"Run the full test suite"

# Create migrations
"Create migrations for the new model"

# Seed database
"Seed the database with demo tenants"

# Update dependencies
"Update all dependencies to latest versions"
```

---

### 7. infrastructure-troubleshooter-agent

**Purpose:** Debug Docker, Celery, Redis, PostgreSQL, and integrations.

**Color:** 🟠 Orange

**What it does:**
- Diagnoses Docker container issues
- Debugs Celery task failures
- Troubleshoots Redis connection problems
- Fixes PostgreSQL issues
- Debugs Plaid integration errors
- Validates webhook configurations

**Common scenarios:**
- "Celery tasks aren't running"
- "Docker container keeps crashing"
- "Redis connection refused"
- "Plaid webhooks not working"
- "Database connection timeout"

---

## Skills Overview

Skills are quick procedures and reference guides for common tasks.

### 1. anti-patterns-reference

**Purpose:** Historical production incident documentation.

**Use when:**
- Explaining why patterns are banned
- Onboarding new team members
- Debating coding rule exceptions
- Understanding validation check origins

**Documented incidents:**
| Incident | What Happened |
|----------|---------------|
| Hardcoded secrets | Doppler tokens committed, now in git history forever |
| Hardcoded IDs | Slack IDs broke across dev/staging/prod |
| N+1 queries | List views took 30+ seconds |
| OAuth context loss | Users stranded at `/error` with no retry path |
| Webhook `return True` | Anyone could forge requests and inject fake data |
| `console.log` | Customer data appeared in browser consoles |
| TypeScript `any` | 72+ files, bugs reached production |
| Hardcoded locales | International customers saw wrong formats |
| No `.full_clean()` | Invalid data written to database |
| No `@transaction.atomic` | Orphaned invoices, data corruption |
| Empty catch blocks | Silent failures, impossible debugging |
| Security bypass flags | One wrong config exposed production |

---

### 2. multi-tenant-security-handbook

**Purpose:** Complete tenant isolation and security guide.

**Use when:**
- Implementing tenant-aware features
- Debugging tenant isolation issues
- Reviewing authentication code
- Implementing API endpoints
- Before deploying tenant changes

**Key sections:**
- Tenant isolation principles
- Query patterns (`filter(tenant=request.tenant)`)
- JWT claims validation
- OAuth flow tenant preservation
- Testing tenant isolation
- Emergency response procedures

---

### 3. code-validation-checklist

**Purpose:** Pre-commit validation checklist.

**Use when:**
- Before committing changes
- During code review
- Debugging failed CI/CD
- Before deployment

**Checks covered:**
1. 🔒 Security: Secrets, tokens, credentials
2. 🆔 Hardcoded IDs: User, tenant, Slack
3. 📝 Code Quality: `console.log`, TypeScript `any`
4. 🌍 Localization: Hardcoded locales/currencies
5. ⚙️ Config: Environment variable defaults
6. ⚠️ Errors: TODO comments, empty catch blocks
7. 🌿 Branch: Protected branch protection
8. 🔐 Auth: Tenant page authentication

---

### 4. query-optimization-helper

**Purpose:** Django ORM optimization reference.

**Use when:**
- Fixing N+1 query problems
- Optimizing slow views
- Writing new querysets
- Code review for performance

**Key patterns:**
```python
# ForeignKey → select_related()
Entry.objects.select_related('tenant', 'account')

# Reverse relations → prefetch_related()
Invoice.objects.prefetch_related('lines')

# Conditional prefetch
Prefetch('lines', queryset=Line.objects.filter(active=True))
```

---

### 5. clear-auth0-cache

**Purpose:** Fix "Loading Crispa" spinner issues.

**Symptoms:**
- Page shows "Loading Crispa" indefinitely
- No API requests in Network tab
- No JavaScript errors in console

**Quick fix:**
```javascript
// Run in browser console
localStorage.clear();
sessionStorage.clear();
location.reload();
```

---

### 6. dependabot-helper

**Purpose:** Manage Dependabot PRs efficiently.

**Use when:**
- Reviewing Dependabot PRs
- Package versions seem already satisfied
- Cleaning up stale Dependabot PRs

**Process:**
1. Parse target version from PR title
2. Check current version in lock file
3. If current >= target, PR is outdated
4. Close with explanation comment

---

### 7. debugging-playbook

**Purpose:** Quick reference for common issues.

**Categories:**
- **Frontend**: React errors, hydration, state issues
- **Backend**: Django errors, serializer problems
- **Database**: Connection, migration, query issues
- **API**: Integration failures, timeout problems
- **Performance**: Slow queries, memory leaks
- **Authentication**: Auth0, JWT, session issues

---

## Usage Examples

### Example 1: Fix a GitHub Issue

```
User: "Fix issue #947 - the timestamp disclosure vulnerability"

Claude: [Uses fix-gh-issue agent]
- Creates branch: security/fix-timestamp-disclosure-947
- Implements fix following security guidelines
- Runs security validator
- Creates PR with "Fixes #947"
```

### Example 2: Review and Merge a PR

```
User: "Review PR #123 and merge if it passes"

Claude: [Uses review-pr agent with --auto-approve]
- Checks if Dependabot and closes if outdated
- Updates base branch if behind
- Monitors CI/CD checks
- Fixes any linting failures
- Approves and merges when green
```

### Example 3: Commit with Validation

```
User: "Commit these changes"

Claude: [Uses commit-push agent]
- Runs all 9 validation checks
- Reports any failures
- Generates commit message: "feat(auth): add password reset flow"
- Pushes to current branch
```

### Example 4: Debug Infrastructure Issue

```
User: "Celery tasks aren't running"

Claude: [Uses infrastructure-troubleshooter agent]
- Checks Celery worker status
- Inspects Redis connection
- Reviews task queue
- Identifies broker URL misconfiguration
- Provides fix
```

---

## Troubleshooting

### Symlink Not Working

```bash
# Remove and recreate
rm -rf .claude-shared
ln -sf ~/.claude-code-config .claude-shared
```

### Agents Not Discovered

```bash
# Verify files exist
ls ~/.claude-code-config/agents/
ls ~/.claude-code-config/skills/

# Check symlink is correct
readlink .claude-shared
```

### Permission Denied

```bash
# Fix permissions on install script
chmod +x ~/.claude-code-config/install.sh
```

### Git Pull Fails

```bash
# Reset and re-clone
rm -rf ~/.claude-code-config
git clone https://github.com/Crispa-ai/claude-code-config.git ~/.claude-code-config
```

---

## Questions?

- **Issues**: [GitHub Issues](https://github.com/Crispa-ai/claude-code-config/issues)
- **Updates**: Check releases for version history
- **Docs**: See README.md for quick reference
