#!/bin/bash
# Installation script for shared Claude Code configuration
# Usage: curl -fsSL https://raw.githubusercontent.com/crispa-org/claude-code-config/main/install.sh | bash

set -e  # Exit on error

REPO_URL="https://github.com/Crispa-ai/claude-code-config"
REPO_BRANCH="${CLAUDE_CONFIG_BRANCH:-main}"
TARGET_DIR=".claude"
SHARED_DIR="$TARGET_DIR/.shared"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Not in a git repository. Please run this script from your project root."
fi

info "Installing Claude Code shared configuration..."
echo ""

# Create .claude directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR/agents" "$TARGET_DIR/skills"
    success "Created $TARGET_DIR directory structure"
else
    info "Found existing $TARGET_DIR directory"
fi

# Clone or update shared config
if [ -d "$SHARED_DIR" ]; then
    info "Updating existing shared configuration..."
    cd "$SHARED_DIR"
    git fetch origin
    git reset --hard "origin/$REPO_BRANCH"
    cd ../..
    success "Updated shared configuration to latest version"
else
    info "Cloning shared configuration from $REPO_URL..."
    git clone --branch "$REPO_BRANCH" "$REPO_URL" "$SHARED_DIR"
    success "Cloned shared configuration"
fi

# Create symlinks for agents
info "Linking agents..."
AGENTS_LINKED=0
for agent in "$SHARED_DIR/agents"/*.md; do
    if [ -f "$agent" ]; then
        agent_name=$(basename "$agent")
        target="$TARGET_DIR/agents/$agent_name"

        # Remove existing symlink or file
        if [ -L "$target" ]; then
            rm "$target"
        elif [ -f "$target" ]; then
            warning "Found existing file $target (not a symlink)"
            echo "   Backing up to ${target}.backup"
            mv "$target" "${target}.backup"
        fi

        # Create symlink (relative path for portability)
        ln -s "../.shared/agents/$agent_name" "$target"
        AGENTS_LINKED=$((AGENTS_LINKED + 1))
    fi
done
success "Linked $AGENTS_LINKED agents"

# Create symlinks for skills
info "Linking skills..."
SKILLS_LINKED=0
for skill in "$SHARED_DIR/skills"/*.md; do
    if [ -f "$skill" ]; then
        skill_name=$(basename "$skill")
        target="$TARGET_DIR/skills/$skill_name"

        # Remove existing symlink or file
        if [ -L "$target" ]; then
            rm "$target"
        elif [ -f "$target" ]; then
            warning "Found existing file $target (not a symlink)"
            echo "   Backing up to ${target}.backup"
            mv "$target" "${target}.backup"
        fi

        # Create symlink (relative path for portability)
        ln -s "../.shared/skills/$skill_name" "$target"
        SKILLS_LINKED=$((SKILLS_LINKED + 1))
    fi
done
success "Linked $SKILLS_LINKED skills"

# Create symlinks for hooks
info "Linking hooks..."
mkdir -p "$TARGET_DIR/hooks"
HOOKS_LINKED=0
for hook in "$SHARED_DIR/hooks"/*; do
    if [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        target="$TARGET_DIR/hooks/$hook_name"

        # Remove existing symlink or file
        if [ -L "$target" ]; then
            rm "$target"
        elif [ -f "$target" ]; then
            warning "Found existing file $target (not a symlink)"
            echo "   Backing up to ${target}.backup"
            mv "$target" "${target}.backup"
        fi

        # Create symlink (relative path for portability)
        ln -s "../.shared/hooks/$hook_name" "$target"
        chmod +x "$target"
        HOOKS_LINKED=$((HOOKS_LINKED + 1))
    fi
done
success "Linked $HOOKS_LINKED hooks"

# Configure git to use shared hooks directory
info "Configuring git hooks..."
git config core.hooksPath .claude/hooks
success "Set git hooks path to .claude/hooks"

# Add .shared to .gitignore if not already present
GITIGNORE=".gitignore"
if [ ! -f "$GITIGNORE" ]; then
    touch "$GITIGNORE"
fi

if ! grep -q "^\.claude/\.shared" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "# Claude Code shared configuration (managed via symlinks)" >> "$GITIGNORE"
    echo ".claude/.shared/" >> "$GITIGNORE"
    success "Added .claude/.shared/ to .gitignore"
else
    info ".claude/.shared/ already in .gitignore"
fi

# Setup Chrome DevTools MCP for browser debugging (optional)
info "Setting up browser debugging MCP..."
CHROME_PATH="/Applications/Google Chrome.app"
MCP_CONFIGURED=false
CHROME_DEVTOOLS_MCP_VERSION="0.16.0"

if [ -d "$CHROME_PATH" ]; then
    if command -v claude &> /dev/null; then
        # Remove existing config if present
        claude mcp remove --scope user chrome-devtools 2>/dev/null || true
        # Add chrome-devtools MCP (non-fatal - don't abort installer on failure)
        if claude mcp add --scope user chrome-devtools -- npx -y "chrome-devtools-mcp@$CHROME_DEVTOOLS_MCP_VERSION" --browserUrl http://localhost:9223 2>/dev/null; then
            MCP_CONFIGURED=true
            success "Chrome DevTools MCP configured (v$CHROME_DEVTOOLS_MCP_VERSION)"
        else
            warning "Failed to configure Chrome DevTools MCP - you can set it up manually later"
        fi

        # Add shell alias for launching Chrome with debugging
        SHELL_RC=""
        [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
        [ -z "$SHELL_RC" ] && [ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"

        if [ -n "$SHELL_RC" ]; then
            if ! grep -q "chrome-debug" "$SHELL_RC"; then
                cat >> "$SHELL_RC" << 'ALIASEOF'

# Chrome with remote debugging for Claude Code (added by claude-code-config)
alias chrome-debug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9223 --user-data-dir=/tmp/chrome-debug-profile"
ALIASEOF
                success "Added 'chrome-debug' shell alias to $SHELL_RC"
            fi
        else
            info "No supported shell rc found (~/.zshrc or ~/.bashrc)"
            echo "   Add this alias manually to your shell config:"
            echo '   alias chrome-debug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9223 --user-data-dir=/tmp/chrome-debug-profile"'
        fi
    else
        warning "Claude CLI not found - skipping MCP setup"
        echo "   Install with: npm install -g @anthropic-ai/claude-code"
    fi
else
    warning "Chrome not found - skipping browser MCP setup"
    echo "   Install with: brew install --cask google-chrome"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Installed:"
echo "  • $AGENTS_LINKED agents"
echo "  • $SKILLS_LINKED skills"
echo "  • $HOOKS_LINKED git hooks (auto-validation on push)"
if [ "$MCP_CONFIGURED" = true ]; then
    echo "  • Chrome DevTools MCP (browser debugging)"
fi
echo ""
info "Location: $TARGET_DIR/"
echo ""
info "What's next?"
echo "  1. Commit the symlinks to your repository:"
echo "     git add .claude/agents .claude/skills .claude/hooks .gitignore"
echo "     git commit -m 'chore: install shared Claude Code config'"
echo ""
echo "  2. Update anytime by running:"
echo "     cd .claude/.shared && git pull && cd ../.."
echo ""
echo "  3. For browser debugging:"
echo "     - Start new terminal (to load alias)"
echo "     - Run: chrome-debug"
echo "     - Navigate to your app"
echo "     - Ask Claude: 'check console for errors'"
echo ""
echo "  4. Pre-push validation runs automatically on every git push"
echo "     - Bypass if needed: git push --no-verify"
echo ""
info "Documentation: https://github.com/Crispa-ai/claude-code-config"
echo ""
