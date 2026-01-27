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

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Installed:"
echo "  • $AGENTS_LINKED agents"
echo "  • $SKILLS_LINKED skills"
echo ""
info "Location: $TARGET_DIR/"
echo ""
info "What's next?"
echo "  1. Commit the symlinks to your repository:"
echo "     git add .claude/agents .claude/skills .gitignore"
echo "     git commit -m 'chore: install shared Claude Code config'"
echo ""
echo "  2. Update anytime by running:"
echo "     cd .claude/.shared && git pull && cd ../.."
echo ""
echo "  3. Or use the GitHub Action for automatic updates (see README)"
echo ""
info "Documentation: https://github.com/Crispa-ai/claude-code-config"
echo ""
