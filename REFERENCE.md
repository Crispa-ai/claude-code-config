# Quick Reference Card

## Agents (Autonomous Workflows)

### fix-gh-issue-agent
**Purpose**: Autonomous GitHub issue resolution

**When to use**: Fixing GitHub issues from open to closed

**Commands**:
```bash
fix-gh-issue --123          # Fix specific issue
fix-gh-issue --all          # Fix all open issues
fix-gh-issue --123 --review # Step-by-step review mode
```

**What it does**:
1. Validates environment (git, GitHub CLI)
2. Fetches issue details
3. Creates semantic branch
4. Implements complete solution
5. Runs tests
6. Creates PR with `Fixes #123`

**Priority order**: Security → Bugs → Features

---

### review-pr-agent
**Purpose**: PR review with pipeline monitoring and auto-fixing

**When to use**: Reviewing PRs, waiting for checks, fixing pipeline failures

**Commands**:
```bash
review-pr --123                # Monitor checks only
review-pr --123 --auto-approve # Fix, approve, merge
review-pr --123 --auto-fix     # Fix failures only
review-pr --123 --no-update    # Skip base update
```

**What it does**:
1. Checks if Dependabot PR is outdated
2. Updates base branch if behind
3. Monitors CI/CD checks
4. Analyzes failures
5. Auto-fixes common issues
6. Approves and merges when passing

**Smart features**:
- Closes outdated Dependabot PRs automatically
- Real-time check monitoring
- Intelligent failure analysis

---

### commit-push-agent
**Purpose**: Smart commit workflow with validation

**When to use**: Committing and pushing changes

**Commands**:
```bash
commit-push                          # Auto-generate message
commit-push --message "feat: add X"  # Custom message
```

**What it does**:
1. Validates git status
2. Creates feature branch if on protected branch
3. Runs MANDATORY pre-commit validation
4. Generates conventional commit message
5. Creates commit with co-author tag
6. Pushes to remote with upstream

**Validation checks** (9 checks):
- Secrets/tokens
- Hardcoded IDs
- console.log
- TypeScript any
- Hardcoded locales
- Env var defaults
- TODO error handling
- Branch protection
- Tenant page auth

---

### code-review-validator
**Purpose**: Comprehensive code review against standards

**When to use**: After writing or modifying code

**Automatically triggered**: When significant code changes are made

**What it checks**:
1. CLAUDE.md compliance
2. Pre-commit validation rules
3. Anti-patterns (N+1 queries, security issues)
4. Code redundancies
5. Architecture consistency
6. Code quality

**Output**: Structured report with:
- ✅ Passed checks
- ❌ Critical issues (MUST FIX)
- ⚠️ High priority issues
- 💡 Recommendations

---

### security-deployment-validator
**Purpose**: Security scanning and deployment safety

**When to use**: Before commits, before deployments, security reviews

**What it checks**:
1. **Security**: Secrets, hardcoded IDs, webhook verification
2. **Authentication**: Tenant page auth (all `/pages/[tenant]/`)
3. **Deployment**: Branch protection, PR workflow
4. **Configuration**: Env vars without defaults

**Scans for**:
- API keys, tokens, passwords in code
- Hardcoded user/tenant/resource IDs
- Webhook handlers returning True
- Missing authentication on tenant pages
- Security bypass flags
- Environment variable defaults

**Critical checks** block deployment if failed

---

## Skills (Quick Procedures)

### clear-auth0-cache
**Purpose**: Fix "Loading Crispa" spinner issues

**Symptom**: Frontend stuck on loading spinner, no API requests

**Quick fix**: Run in browser console:
```javascript
localStorage.clear();
sessionStorage.clear();
location.reload();
```

**When to use**: Auth0 session issues, infinite loading

---

### code-validation-checklist
**Purpose**: Complete pre-commit validation

**When to use**: Before committing, during code review, debugging CI failures

**What it validates** (12 checks):
1. 🔒 Secrets/tokens
2. 🔒 Hardcoded IDs
3. 🔒 Webhook verification
4. 📝 console.log
5. 📝 TypeScript any
6. 📝 TODO error handling
7. 🌍 Hardcoded locales
8. ⚡ N+1 queries
9. 🔐 Tenant page auth
10. 🚫 Env var defaults
11. 🏗️ Branch protection
12. 🏗️ Django model validation

**Output**: Pass/fail for each check with specific violations

**Script included**: Complete bash validation script

---

### query-optimization-helper
**Purpose**: Django ORM query optimization reference

**When to use**: Fixing N+1 queries, optimizing database performance

**Covers**:
- What is N+1 query problem
- When to use `select_related()` (ForeignKey)
- When to use `prefetch_related()` (M2M, reverse FK)
- Combining both
- Advanced: Prefetch objects
- Other optimizations (only, defer, values, values_list)
- DRF viewset patterns
- Debugging with Django Debug Toolbar

**Examples**: Real-world before/after comparisons

**Decision tree** included for quick reference

---

### dependabot-helper
**Purpose**: Manage and close outdated Dependabot PRs

**When to use**: Reviewing Dependabot PRs, cleaning up stale PRs

**What it does**:
1. Identifies Dependabot PRs
2. Parses target version from PR title
3. Checks current version in lock files
4. Compares versions (semver)
5. Closes PR if outdated with explanation

**Supports**:
- npm/Yarn packages (package.json, yarn.lock)
- Python packages (requirements.txt, poetry.lock)
- Semver comparison
- Transitive dependencies

**Example workflow included**

---

## Usage Patterns

### Daily Development
```
1. Write code
2. [code-review-validator runs automatically]
3. commit-push
   → [Runs code-validation-checklist]
   → Creates commit
   → Pushes to remote
```

### Fixing Issues
```
1. fix-gh-issue --123
   → Analyzes issue
   → Implements fix
   → Runs tests
   → Creates PR

2. review-pr --123 --auto-approve
   → Monitors checks
   → Auto-fixes failures
   → Approves when passing
   → Merges automatically
```

### Security Review
```
1. [security-deployment-validator runs]
   → Scans for secrets
   → Checks authentication
   → Validates deployment safety
   → Reports issues
```

### Performance Debugging
```
1. Check [query-optimization-helper]
   → Understand N+1 problem
   → Find correct optimization
   → Apply fix

2. [code-review-validator runs]
   → Verifies optimization
```

---

## File Locations

After installation:

```
.claude/
├── agents/
│   ├── fix-gh-issue-agent.md → ../.shared/agents/fix-gh-issue-agent.md
│   ├── review-pr-agent.md → ../.shared/agents/review-pr-agent.md
│   ├── commit-push-agent.md → ../.shared/agents/commit-push-agent.md
│   ├── code-review-validator.md → ../.shared/agents/code-review-validator.md
│   └── security-deployment-validator.md → ../.shared/agents/security-deployment-validator.md
└── skills/
    ├── clear-auth0-cache.md → ../.shared/skills/clear-auth0-cache.md
    ├── code-validation-checklist.md → ../.shared/skills/code-validation-checklist.md
    ├── query-optimization-helper.md → ../.shared/skills/query-optimization-helper.md
    └── dependabot-helper.md → ../.shared/skills/dependabot-helper.md
```

---

## Quick Command Reference

```bash
# Install shared config
curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash

# Update shared config
cd .claude/.shared && git pull

# View agent/skill content
cat .claude/agents/fix-gh-issue-agent.md
cat .claude/skills/code-validation-checklist.md

# Check symlink targets
readlink .claude/agents/fix-gh-issue-agent.md

# List all agents
ls -la .claude/agents/

# List all skills
ls -la .claude/skills/
```

---

## Tips & Tricks

### When in Doubt
1. Check the agent/skill documentation
2. Reference CLAUDE.md for project-specific rules
3. Use `--review` flag for step-by-step guidance

### Best Practices
- Let agents run autonomously for routine tasks
- Use review mode for complex or risky changes
- Reference skills when you need quick guidance
- Keep agents updated for latest improvements

### Troubleshooting
- **Agent not working**: Check symlink exists and is valid
- **Validation failing**: Read the specific error message
- **Updates not applying**: Run `cd .claude/.shared && git pull`

---

## Integration with CLAUDE.md

CLAUDE.md references these agents/skills:

```markdown
## Claude Commands

### fix-gh-issue Command
[High-level description]
**Full implementation**: See `.claude/agents/fix-gh-issue-agent.md`

### review-pr Command
[High-level description]
**Full implementation**: See `.claude/agents/review-pr-agent.md`

## Anti-Patterns

### N+1 Queries
[Example and rule]
**Detailed guide**: See `.claude/skills/query-optimization-helper.md`
```

This keeps CLAUDE.md concise while providing detailed implementations in agents/skills.

---

## Summary

| Type | Count | Purpose |
|------|-------|---------|
| Agents | 5 | Autonomous multi-step workflows |
| Skills | 4 | Quick reference procedures |
| Total Lines | ~5,000 | Reusable configuration |

**Result**: Consistent workflows across all repositories with centralized maintenance.

---

Print this reference card and keep it handy! 📋
