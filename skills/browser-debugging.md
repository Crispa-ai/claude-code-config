# Browser Debugging Skill

Debug frontend issues directly in Chrome using Claude Code's Chrome DevTools MCP integration.

## Quick Start

1. **Launch Chrome with debugging:**

   ```bash
   chrome-debug
   ```

2. **Navigate to your app** (e.g., `localhost:3000`)

3. **Ask Claude to debug:**
   - "Check the console for errors"
   - "Take a screenshot of the current page"
   - "Show me failed network requests"
   - "Click the submit button and capture any errors"

## Setup

The browser MCP is automatically configured by the install script. If you need to set it up manually:

```bash
# Install Chrome (if needed)
brew install --cask google-chrome

# Add MCP to Claude Code
claude mcp add --scope user chrome-devtools -- npx -y chrome-devtools-mcp@0.16.0 --browserUrl http://localhost:9223

# Add alias to your shell (zsh)
echo 'alias chrome-debug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9223 --user-data-dir=/tmp/chrome-debug-profile"' >> ~/.zshrc
source ~/.zshrc
```

## Available Tools

### Page Inspection

| Tool | Description | Example Prompt |
|------|-------------|----------------|
| `take_screenshot` | Capture page visuals | "Take a screenshot of the dashboard" |
| `take_snapshot` | Get accessibility tree with element UIDs | "Get the page structure" |
| `list_pages` | List all open browser tabs | "What pages are open?" |

### Console & Debugging

| Tool | Description | Example Prompt |
|------|-------------|----------------|
| `list_console_messages` | View console logs, errors, warnings | "Show me console errors" |
| `get_console_message` | Get details of a specific message | "Get details on that error" |
| `evaluate_script` | Run JavaScript in page context | "Run `localStorage.getItem('token')` in the page" |

### Network Monitoring

| Tool | Description | Example Prompt |
|------|-------------|----------------|
| `list_network_requests` | Monitor all API calls | "Show me network requests" |
| `get_network_request` | Get full request/response details | "Get the response body from that API call" |

### Browser Automation

| Tool | Description | Example Prompt |
|------|-------------|----------------|
| `click` | Click an element by UID | "Click the submit button" |
| `fill` | Type into input fields | "Fill the email field with test@example.com" |
| `navigate_page` | Go to URL, back, forward, reload | "Navigate to /settings" |
| `hover` | Hover over an element | "Hover over the dropdown menu" |

### Performance

| Tool | Description | Example Prompt |
|------|-------------|----------------|
| `performance_start_trace` | Start recording performance trace | "Record performance while I interact with the page" |
| `performance_stop_trace` | Stop recording and analyze | "Stop recording and show insights" |

## Common Debugging Workflows

### Debug a Form Submission

```text
1. "Take a snapshot of the form"
2. "Fill the form fields with test data"
3. "Click submit and capture network requests"
4. "Show me any console errors"
```

### Debug a Loading Issue

```text
1. "Navigate to /dashboard and take a screenshot"
2. "Show me all network requests"
3. "Are there any failed API calls?"
4. "Check console for errors"
```

### Debug a Visual Bug

```text
1. "Take a screenshot of the page"
2. "Get the snapshot - I need to find element X"
3. "Evaluate: window.getComputedStyle(document.querySelector('.broken-element'))"
```

## Troubleshooting

### "Network.enable timed out"

This happens with Chromium-based browsers like Dia/Arc. Use standard Chrome:

```bash
# Kill other browsers using the debug port
lsof -i :9223

# Launch Chrome with fresh profile
chrome-debug
```

### Chrome not connecting

```bash
# Verify Chrome is running with debugging
curl http://localhost:9223/json/version

# Should return JSON with browser info
```

### MCP not available after install

Restart Claude Code to load new MCP configuration:

```bash
# Verify MCP is configured
claude mcp list | grep chrome
```

## Requirements

- **Google Chrome** - `brew install --cask google-chrome`
- **Claude Code CLI** - `npm install -g @anthropic-ai/claude-code`
- **Node.js 18+**

## Notes

- The `chrome-debug` alias uses a temporary profile to avoid conflicts with your main Chrome profile
- On multi-user systems, consider using `$TMPDIR/chrome-debug-$USER` instead of `/tmp/chrome-debug-profile`
- Only one Chrome instance can use the debug port at a time
- These setup instructions are macOS-specific; Linux/Windows users should adapt paths accordingly
