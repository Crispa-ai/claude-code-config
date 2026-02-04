# Claude Code Shared Config

Shared agents, skills, and git hooks for Crispa repos.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Crispa-ai/claude-code-config/main/install.sh | bash
```

Installs:
- Agents and skills (symlinks)
- Pre-push validation hooks
- Chrome DevTools MCP (browser debugging)
- `chrome-debug` shell alias

After install, commit the symlinks:
```bash
git add .claude/agents .claude/skills .claude/hooks .gitignore
git commit -m "chore: install shared Claude Code config"
```

## Update

```bash
cd .claude/.shared && git pull && cd ../..
```

---

## Commands

### GitHub Issues

```bash
fix-gh-issue --123              # Fix issue #123
fix-gh-issue --all              # Fix all open issues
fix-gh-issue --123 --review     # Step-by-step approval mode
```

### PR Review

```bash
review-pr --123                 # Monitor PR checks
review-pr --123 --auto-approve  # Auto-fix, approve, merge
review-pr --123 --no-update     # Skip base branch update
```

### Commit & Push

```bash
commit-push                     # Auto-generate message, validate, push
commit-push --message "fix: X"  # Custom commit message
```

---

## Git Hooks

Pre-push validation runs automatically on `git push`:

| Check | Blocks push? |
|-------|--------------|
| Secrets/tokens | Yes |
| `console.log` in prod code | Yes |
| Missing tenant page auth | Yes |
| TypeScript `any` | Warning |
| Hardcoded IDs | Warning |
| N+1 query patterns | Warning |

Bypass: `git push --no-verify`

---

## Browser Debugging

Debug frontend from Claude Code:

```bash
# Terminal 1: Launch Chrome with debugging
chrome-debug

# Terminal 2: Claude Code
# Navigate to localhost:3000 in Chrome, then ask:
# "check console for errors"
# "take a screenshot"
# "show failed network requests"
```

---

## Skills Reference

| Skill | When to use |
|-------|-------------|
| `anti-patterns-reference` | Check past incidents before implementing |
| `code-validation-checklist` | Pre-commit checks |
| `query-optimization-helper` | Django N+1 fixes |
| `multi-tenant-security-handbook` | OAuth, tenant isolation |
| `browser-debugging` | Chrome DevTools MCP |
| `debugging-playbook` | Common issue debugging |
| `clear-auth0-cache` | "Loading Crispa" spinner fix |
| `dependabot-helper` | Close stale Dependabot PRs |
| `complypay-payments-api` | ComplyPay API reference |

---

## Agents Reference

| Agent | Trigger |
|-------|---------|
| `fix-gh-issue-agent` | `fix-gh-issue` command |
| `review-pr-agent` | `review-pr` command |
| `commit-push-agent` | `commit-push` command |
| `code-review-validator` | Auto after code changes |
| `security-deployment-validator` | Auto before commits |
| `full-stack-dev-agent` | Full dev workflow |
| `infrastructure-troubleshooter-agent` | Docker/DB debugging |

---

## Project Structure

```
.claude/
├── .shared/      # This repo (gitignored)
├── agents/       # Symlinks → .shared/agents/
├── skills/       # Symlinks → .shared/skills/
└── hooks/        # Symlinks → .shared/hooks/
```

---

## Customization

Add repo-specific agents/skills directly (not symlinks):
```bash
vim .claude/agents/my-custom-agent.md
```

Override a shared one:
```bash
rm .claude/agents/code-review-validator.md
vim .claude/agents/code-review-validator.md
```

---

## Contributing

1. Clone repo
2. Create branch
3. Edit files
4. Test: `cd .claude/.shared && git checkout your-branch`
5. PR

---

## Other Docs

- [GUIDE.md](GUIDE.md) - Detailed docs
- [QUICK_START.md](QUICK_START.md) - Quick start
- [REFERENCE.md](REFERENCE.md) - Full command reference
