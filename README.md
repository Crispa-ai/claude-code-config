# Claude Code Shared Config

Shared agents, skills, and git hooks for Crispa repos.

---

## Prerequisites

1. **Claude Code CLI**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **GitHub CLI** (for issue/PR agents)

   ```bash
   # macOS
   brew install gh
   gh auth login
   ```

   Other platforms: <https://github.com/cli/cli#installation>

3. **Google Chrome** (for browser debugging)

   ```bash
   # macOS
   brew install --cask google-chrome
   ```

   Other platforms: <https://www.google.com/chrome/>

---

## Installation

### Step 1: Run install script

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Crispa-ai/claude-code-config/main/install.sh | bash
```

This automatically:
- Clones shared config to `.claude/.shared/`
- Creates symlinks for agents, skills, hooks
- Sets `git config core.hooksPath .claude/hooks`
- Configures Chrome DevTools MCP (if Chrome installed)
- Adds `chrome-debug` alias to your shell

### Step 2: Commit the symlinks

```bash
git add .claude/agents .claude/skills .claude/hooks .gitignore
git commit -m "chore: install shared Claude Code config"
```

### Step 3: Start new terminal

Required to load the `chrome-debug` alias.

### Step 4: Restart Claude Code

Required to load the new MCP configuration.

---

## Updating

```bash
cd .claude/.shared && git pull && cd ../..
```

---

## Verify Installation

```bash
# Check hooks are configured
git config core.hooksPath
# Should output: .claude/hooks

# Check MCP is configured
claude mcp list | grep chrome
# Should show: chrome-devtools

# Check alias works (new terminal)
type chrome-debug
# Should show: chrome-debug is aliased to ...
```

---

## How Agents & Skills Work

### Agents vs Normal Chat

| Mode | How it works |
|------|--------------|
| **Normal chat** | Claude responds based on general knowledge + codebase context |
| **Using an agent** | Claude follows a specific workflow defined in the agent file |

### How to Invoke Agents

**Method 1: Slash commands** (for command-based agents)

```text
fix-gh-issue --123
review-pr --456 --auto-approve
commit-push
```

**Method 2: Explicitly reference the agent**

```text
User: Use the full-stack-dev-agent to add a new API endpoint for invoices
User: Run the infrastructure-troubleshooter-agent to debug why Celery is stuck
```

**Method 3: Automatic** (some agents trigger based on context)
- `code-review-validator` - runs after you write code
- `security-deployment-validator` - runs before commits

### How to Invoke Skills

Reference the skill name in your message:

```text
User: Check the anti-patterns-reference before I implement this webhook
User: Use the query-optimization-helper to fix these slow queries
User: What does the multi-tenant-security-handbook say about OAuth state?
```

### How to Know You're Using an Agent

When an agent is active, Claude will:
1. Follow the specific workflow defined in the agent
2. Often show structured output (phases, checkpoints)
3. Reference the agent's rules and requirements

If you just chat normally without invoking an agent, Claude uses general knowledge.

**Tip:** If you want a specific workflow, always explicitly invoke the agent.

---

## Agents

### fix-gh-issue-agent

Fixes GitHub issues autonomously - creates branch, implements fix, submits PR.

```bash
fix-gh-issue --123              # Fix issue #123
fix-gh-issue --all              # Fix all open issues (security first, then bugs, then features)
fix-gh-issue --123 --review     # Step-by-step approval mode
```

Example conversation:
```
User: fix-gh-issue --456
Claude: [Reads issue #456, creates branch security/fix-auth-bypass-456,
        implements fix, runs tests, creates PR with "Fixes #456"]
```

### review-pr-agent

Reviews PRs, monitors CI/CD, auto-fixes failures, merges when ready.

```bash
review-pr --123                 # Monitor PR #123 checks only
review-pr --123 --auto-approve  # Auto-fix failures, approve, merge when passing
review-pr --123 --auto-fix      # Fix failures but don't approve
review-pr --123 --no-update     # Skip base branch update
```

Example conversation:
```
User: review-pr --789 --auto-approve
Claude: [Checks if Dependabot PR is stale, updates base branch,
        monitors CI checks, fixes lint errors, approves, merges]
```

### commit-push-agent

Validates code, generates commit message, pushes. Creates feature branch if on protected branch.

```bash
commit-push                     # Auto-generate conventional commit message
commit-push --message "fix: resolve auth timeout"  # Custom message
```

Example conversation:
```
User: commit-push
Claude: [Runs CLAUDE.md validation, stages changes, generates
        "feat: add invoice export to PDF", commits, pushes]
```

### code-review-validator

Triggered automatically after code changes. Reviews against CLAUDE.md rules.

Checks:
- Anti-patterns (N+1 queries, hardcoded IDs, secrets)
- Security (tenant auth, env var defaults)
- Code quality (console.log, TypeScript any)
- Architecture consistency

Example conversation:
```
User: [writes some code]
Claude: [Automatically validates] Found 2 issues:
        - Line 45: Missing select_related() - potential N+1 query
        - Line 89: console.log should be removed
```

### security-deployment-validator

Triggered before commits and deployments. Validates security requirements.

Checks:
- Secrets/API keys in code
- Hardcoded user/tenant IDs
- Tenant page authentication (`withAuthenticationRequired`)
- Environment variable defaults (not allowed)
- Branch protection compliance

Example conversation:
```
User: commit-push
Claude: [Runs security validator] BLOCKED:
        - pages/[tenant]/settings.tsx missing authentication
        - Found hardcoded tenant_id on line 34
```

### full-stack-dev-agent

Complete development workflow for feature implementation.

Example conversation:
```
User: I need to add a new API endpoint for exporting invoices
Claude: [Creates migration, model, serializer, view, URL config,
        frontend API client, component, runs tests, seeds demo data]
```

### infrastructure-troubleshooter-agent

Debugs Docker, Celery, Redis, PostgreSQL, and integration issues.

Example conversation:
```
User: Celery tasks are stuck
Claude: [Checks Redis connection, Celery worker status, task queue,
        inspects failed tasks, identifies deadlock, suggests fix]
```

---

## Skills

### anti-patterns-reference

Reference of past production incidents. Check before implementing similar features.

Example conversation:
```
User: I'm adding a webhook handler, any gotchas?
Claude: [References anti-patterns] Key issues to avoid:
        - Never return True without actual signature verification
        - Always use @transaction.atomic for multi-model operations
        - Log to Sentry, not console
```

### code-validation-checklist

Pre-commit validation checklist. Run before committing.

Example conversation:
```
User: Run the validation checklist on my changes
Claude: [Runs checklist]
        ✓ No secrets detected
        ✓ No console.log
        ✗ TypeScript 'any' found on line 23
        ✓ Tenant pages have auth
        ✗ Missing select_related() on line 67
```

### query-optimization-helper

Django ORM optimization guide.

Example conversation:
```
User: This view is slow, can you optimize the queries?
Claude: [References optimization helper]
        - Use select_related('tenant', 'created_by') for ForeignKey
        - Use prefetch_related('line_items') for reverse relations
        - Add .only('id', 'name', 'amount') to limit fields
```

### multi-tenant-security-handbook

Tenant isolation, OAuth flows, security patterns.

Example conversation:
```
User: How do I add a new OAuth integration?
Claude: [References handbook]
        1. Store tenant_slug in OAuth state parameter
        2. Validate tenant on callback
        3. Use TenantAwareOAuthMixin
        4. Never expose tokens in frontend
```

### browser-debugging

Chrome DevTools MCP usage guide.

Example conversation:
```
User: The form isn't submitting, help me debug
Claude: [Uses browser MCP]
        - Takes screenshot
        - Checks console: "TypeError: Cannot read 'id' of undefined"
        - Inspects network: POST /api/invoices returned 400
        - Shows response body with validation error
```

### debugging-playbook

Common issue debugging reference.

Example conversation:
```
User: Getting 500 errors on the invoice page
Claude: [References playbook]
        1. Check Sentry for stack trace
        2. Check recent deployments
        3. Verify database migrations ran
        4. Check Redis/Celery status
```

### clear-auth0-cache

Fix "Loading Crispa" spinner issues.

Example conversation:
```
User: User is stuck on loading screen
Claude: Have them run in browser console:
        localStorage.clear();
        sessionStorage.clear();
        location.reload();
```

### dependabot-helper

Manage Dependabot PRs.

Example conversation:
```
User: There are 15 Dependabot PRs, help me clean up
Claude: [Checks each PR]
        - #234: axios 1.5.0→1.6.0 - already at 1.6.2 in lock file, closing
        - #235: react 18.2→18.3 - legitimate upgrade, keep open
        - #236: lodash 4.17.20→4.17.21 - security fix, prioritize
```

### complypay-payments-api

ComplyPay Payments API reference.

Example conversation:
```
User: How do I initiate a payment?
Claude: [References API docs]
        POST /api/v1/payments/
        {
          "amount": 10000,  // cents
          "currency": "DKK",
          "recipient_id": "...",
          "reference": "INV-001"
        }
        States: pending → processing → completed/failed
```

---

## Git Hooks

### Pre-push Hook

Runs automatically on `git push` (not on commit). Provides last-line-of-defense validation before code reaches the remote.

| Check | Blocks push? |
|-------|--------------|
| Secrets/tokens | Yes |
| `console.log` in prod code | Yes |
| Missing tenant page auth | Yes |
| TypeScript `any` | Warning |
| Hardcoded IDs | Warning |
| N+1 query patterns | Warning |

**Bypass:** `git push --no-verify`

**Note:** For faster local feedback, run validation manually before committing:

```bash
.claude/scripts/pre-commit-validate.sh
```

---

## Browser Debugging

Debug frontend directly from Claude Code using Chrome DevTools MCP.

### Setup

```bash
# Terminal 1: Launch Chrome with debugging
chrome-debug

# Navigate to localhost:3000 in Chrome
# Then use Claude Code normally
```

### Available Tools

**Screenshots & Page State**

| Tool | What it does |
|------|--------------|
| `take_screenshot` | Capture full page or element screenshot |
| `take_snapshot` | Get accessibility tree with element IDs for automation |
| `list_pages` | List all open browser tabs |
| `select_page` | Switch to a different tab |

**Console & Debugging**

| Tool | What it does |
|------|--------------|
| `list_console_messages` | View all console logs, errors, warnings |
| `get_console_message` | Get details of specific message |
| `evaluate_script` | Run JavaScript in page context |

**Network Monitoring**

| Tool | What it does |
|------|--------------|
| `list_network_requests` | See all API calls (XHR, fetch, etc.) |
| `get_network_request` | Get full request/response headers and body |

**Browser Automation**

| Tool | What it does |
|------|--------------|
| `click` | Click element by ID from snapshot |
| `fill` | Type into input fields |
| `fill_form` | Fill multiple form fields at once |
| `hover` | Hover over element |
| `press_key` | Press keyboard keys (Enter, Tab, etc.) |
| `navigate_page` | Go to URL, back, forward, reload |
| `upload_file` | Upload file to file input |
| `handle_dialog` | Accept/dismiss alert dialogs |

**Performance**

| Tool | What it does |
|------|--------------|
| `performance_start_trace` | Start recording performance trace |
| `performance_stop_trace` | Stop and analyze trace |
| `performance_analyze_insight` | Get specific performance insights |

**Page Control**

| Tool | What it does |
|------|--------------|
| `new_page` | Open new browser tab |
| `close_page` | Close a tab |
| `resize_page` | Change viewport size |
| `emulate` | Emulate mobile, dark mode, geolocation, network throttling |
| `wait_for` | Wait for text to appear on page |

### Example Prompts

```
"check console for errors"
"take a screenshot of the dashboard"
"show me all failed network requests"
"what API calls happen when I click submit?"
"fill the login form with test@example.com and password123"
"click the Save button and capture the response"
"emulate slow 3G network and reload the page"
"run localStorage.getItem('token') in the page"
"wait for 'Success' to appear then take a screenshot"
```

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
