---
name: dependabot-helper
description: Procedure for managing and cleaning up Dependabot PRs. Use when triaging multiple dependency-upgrade PRs and closing stale ones.
---

# Dependabot Helper

**Quick procedure for managing Dependabot PRs and closing outdated upgrade requests.**

## When to Use

- When reviewing Dependabot PRs
- When package versions seem already satisfied
- Before running CI/CD on Dependabot PRs
- To clean up stale Dependabot PRs

## The Outdated Dependabot Problem

### What Happens

Dependabot creates a PR to upgrade `package@1.0.0` → `package@1.5.0`, but meanwhile:
- Another dependency upgraded transitively brought in `package@1.6.0`
- A manual upgrade was done
- Another Dependabot PR for a parent package included the upgrade

Result: The Dependabot PR is now outdated and unnecessary.

### Why Close Them

- Reduces PR noise and review burden
- Prevents merge conflicts
- Avoids downgrading packages accidentally
- Keeps dependencies clean

## Quick Check Procedure

### Step 1: Identify Dependabot PR

Check if PR is from Dependabot:
- **Author**: `dependabot[bot]` or `dependabot`
- **Branch**: `dependabot/npm_and_yarn/*` or `dependabot/pip/*`
- **Title**: Pattern like "bump {package} from {old} to {new}"

```bash
gh pr view 123 --json author,headRefName,title
```

### Step 2: Parse Target Version

Extract package name and target version from PR title:

**Examples:**
- "bump eslint-plugin-react from 7.32.2 to 7.37.5 in /frontend"
  - Package: `eslint-plugin-react`
  - Target: `7.37.5`
  - Path: `/frontend`

- "bump django from 4.1.0 to 4.2.5"
  - Package: `django`
  - Target: `4.2.5`

### Step 3: Check Current Version

#### For NPM/Yarn Packages

**Option 1: Check package.json**
```bash
# Navigate to package path (e.g., /frontend)
cd frontend

# Check current version
cat package.json | grep -A1 '"eslint-plugin-react"'

# Output example:
# "eslint-plugin-react": "^7.38.0",
```

**Option 2: Check yarn.lock**
```bash
# Find package in yarn.lock
grep -A3 '"eslint-plugin-react@' frontend/yarn.lock | head -5

# Output example:
# eslint-plugin-react@^7.38.0:
#   version "7.38.0"
#   resolved "..."
```

**Option 3: Use yarn why**
```bash
cd frontend
yarn why eslint-plugin-react

# Shows current version and why it's installed
```

#### For Python/pip Packages

**Option 1: Check requirements.txt**
```bash
grep -i "^django" backend/requirements.txt

# Output example:
# Django==4.2.7
```

**Option 2: Check poetry.lock** (if using Poetry)
```bash
grep -A5 'name = "django"' backend/poetry.lock | grep version

# Output example:
# version = "4.2.7"
```

**Option 3: Check pip list**
```bash
pip list | grep -i django

# Output example:
# Django  4.2.7
```

### Step 4: Compare Versions

Use semantic versioning comparison:

```
Major.Minor.Patch
  ↓     ↓     ↓
  4  .  2  .  7
```

**Comparison Rules:**
- Compare major version first
- If equal, compare minor version
- If equal, compare patch version

**Examples:**
- `4.2.7 > 4.2.5` ✅ Current is newer
- `7.38.0 > 7.37.5` ✅ Current is newer
- `7.35.0 < 7.37.5` ❌ Target is newer
- `4.2.0 = 4.2.0` ✅ Already at target

### Step 5: Close if Outdated

If current version >= target version, close the PR:

```bash
gh pr close 123 --comment "$(cat <<'EOF'
🔄 **Closing as Outdated**

This Dependabot PR is no longer needed. The codebase already has `{package}@{current_version}` which satisfies or exceeds the target version `{target_version}`.

**Verification:**
```
{command used to check version}
{output showing current version}
```

**Likely reasons this PR became outdated:**
- Package was updated as a transitive dependency
- Manual upgrade was performed
- Another Dependabot PR for a parent package included this update

No action needed - the dependency is already up to date or newer.

🤖 Auto-closed by Claude Code
EOF
)"
```

**Example:**
```bash
gh pr close 456 --comment "$(cat <<'EOF'
🔄 **Closing as Outdated**

This Dependabot PR is no longer needed. The codebase already has `eslint-plugin-react@7.38.0` which exceeds the target version `7.37.5`.

**Verification:**
```
$ grep eslint-plugin-react frontend/package.json
"eslint-plugin-react": "^7.38.0"
```

**Likely reasons this PR became outdated:**
- Package was updated as a transitive dependency
- Manual upgrade was performed
- Another Dependabot PR for a parent package included this update

No action needed - the dependency is already up to date.

🤖 Auto-closed by Claude Code
EOF
)"
```

## Complete Example Workflow

### Scenario: Dependabot PR #789

**PR Title**: "bump typescript from 5.2.0 to 5.3.0 in /frontend"

### Workflow:

```bash
# 1. Verify it's a Dependabot PR
gh pr view 789 --json author,headRefName
# Confirms: author=dependabot[bot], branch=dependabot/npm_and_yarn/frontend/typescript-5.3.0

# 2. Check current version
cd frontend
cat package.json | grep '"typescript"'
# Output: "typescript": "^5.4.0"

# 3. Compare: 5.4.0 > 5.3.0 ✅ Already satisfied

# 4. Close the PR
gh pr close 789 --comment "$(cat <<'EOF'
🔄 **Closing as Outdated**

This Dependabot PR is no longer needed. The codebase already has `typescript@5.4.0` which exceeds the target version `5.3.0`.

**Verification:**
```
$ cat frontend/package.json | grep typescript
"typescript": "^5.4.0"
```

TypeScript was likely upgraded transitively by another dependency or manually updated.

No action needed - the dependency is already up to date.

🤖 Auto-closed by Claude Code
EOF
)"

# 5. Confirm closure
gh pr view 789 --json state
# Output: "state": "CLOSED"
```

## Handling Edge Cases

### Caret (^) and Tilde (~) Ranges

When you see version ranges in package.json:

**Caret (^)**: Compatible with minor and patch updates
```json
"typescript": "^5.3.0"  // Matches >=5.3.0 <6.0.0
```

**Tilde (~)**: Compatible with patch updates only
```json
"typescript": "~5.3.0"  // Matches >=5.3.0 <5.4.0
```

**Check actual installed version** in lock file, not package.json range:
```bash
grep -A3 '"typescript@' yarn.lock | head -5
```

### Pre-release Versions

Be careful with pre-release versions (alpha, beta, rc):
```
5.3.0-alpha.1 < 5.3.0  // Pre-release is lower than release
5.3.0 < 5.3.1-beta.1   // Pre-release of next patch is higher
```

### Different Package Managers

**Yarn Classic (v1)**: `yarn.lock`
**Yarn Berry (v2+)**: `.yarn/cache/`
**npm**: `package-lock.json`
**pnpm**: `pnpm-lock.yaml`
**pip**: `requirements.txt`
**Poetry**: `poetry.lock`
**Pipenv**: `Pipfile.lock`

Always check the lock file for the exact installed version!

## Bulk Dependabot Cleanup

Clean up multiple outdated Dependabot PRs:

```bash
#!/bin/bash
# List all open Dependabot PRs
gh pr list --author dependabot --state open --json number,title,headRefName

# For each PR, check if outdated and close
# (manual verification recommended)
```

## When NOT to Close

Don't close if:
- Current version < target version (upgrade still needed)
- Security advisory mentions the specific version
- Breaking changes in target version need testing
- PR includes additional changes beyond version bump

## Integration with review-pr Agent

The `review-pr` agent automatically runs this check before monitoring CI/CD:

```bash
review-pr --123  # Automatically checks if Dependabot PR is outdated
```

If outdated, it closes the PR and stops - saving CI/CD resources!

## Version Comparison Cheat Sheet

| Current | Target | Action |
|---------|--------|--------|
| 5.4.0 | 5.3.0 | ✅ Close (current is newer) |
| 5.3.0 | 5.3.0 | ✅ Close (already at target) |
| 5.2.0 | 5.3.0 | ❌ Keep (upgrade needed) |
| 5.3.1 | 5.3.0 | ✅ Close (current is newer) |
| 5.3.0 | 6.0.0 | ❌ Keep (major upgrade needed) |
| 6.0.0 | 5.9.0 | ✅ Close (current is newer major) |

## Quick Commands Reference

```bash
# Check if PR is from Dependabot
gh pr view <number> --json author,headRefName,title

# Check npm package version
cat package.json | grep "<package>"
grep "<package>@" yarn.lock

# Check Python package version
grep "^<package>" requirements.txt
pip show <package> | grep Version

# Close outdated PR
gh pr close <number> --comment "<message>"

# List all Dependabot PRs
gh pr list --author dependabot --state open
```

## Summary

1. ✅ Identify Dependabot PRs by author and branch
2. ✅ Parse target version from PR title
3. ✅ Check current version in lock files (not package.json ranges)
4. ✅ Compare versions using semver rules
5. ✅ Close if current >= target with detailed explanation
6. ✅ Save CI/CD resources and reduce PR clutter

This skill keeps your dependency management clean and efficient!
