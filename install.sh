#!/bin/bash
# One-liner installer for Claude Code Share Plugin
# Usage: curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | bash

set -e

echo "🚀 Installing Claude Code Share Plugin..."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: GitHub CLI is not authenticated."
    echo "Run: gh auth login"
    exit 1
fi

# Detect shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    echo "⚠️  Could not detect shell profile (.zshrc or .bashrc)"
    SHELL_PROFILE="$HOME/.zshrc"
fi

echo "📝 Configuring environment variables..."
echo ""

# Prompt for configuration
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter repository for sessions (format: owner/repo): " SESSIONS_REPO
read -p "Enter branch name (default: main): " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-main}
read -p "Enter base path in repo (default: sessions): " BASE_PATH
BASE_PATH=${BASE_PATH:-sessions}

# Check if config already exists
if grep -q "CLAUDE_SHARE_REPO" "$SHELL_PROFILE" 2>/dev/null; then
    echo ""
    echo "⚠️  Configuration already exists in $SHELL_PROFILE"
    read -p "Overwrite existing configuration? (y/N): " OVERWRITE
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
        echo "Skipping environment variable setup..."
    else
        # Remove old config
        sed -i.bak '/# Claude Code Session Sharing Plugin/,/^$/d' "$SHELL_PROFILE"
    fi
fi

# Add configuration to shell profile
if [[ ! $(grep -q "CLAUDE_SHARE_REPO" "$SHELL_PROFILE" 2>/dev/null) ]]; then
    cat >> "$SHELL_PROFILE" << EOF

# Claude Code Session Sharing Plugin Configuration
export CLAUDE_SHARE_REPO="$SESSIONS_REPO"
export CLAUDE_SHARE_USERNAME="$GITHUB_USERNAME"
export CLAUDE_SHARE_BRANCH="$BRANCH_NAME"
export CLAUDE_SHARE_BASE_PATH="$BASE_PATH"
EOF
    echo "✅ Added configuration to $SHELL_PROFILE"
fi

echo ""
echo "✅ Environment configuration complete!"
echo ""

# Export variables for current script session
export CLAUDE_SHARE_REPO="$SESSIONS_REPO"
export CLAUDE_SHARE_USERNAME="$GITHUB_USERNAME"
export CLAUDE_SHARE_BRANCH="$BRANCH_NAME"
export CLAUDE_SHARE_BASE_PATH="$BASE_PATH"

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "⚠️  Claude CLI not found in PATH"
    echo ""
    echo "Next steps:"
    echo "1. Open a new terminal (to load environment variables)"
    echo "2. Start Claude Code and run:"
    echo "   /plugin marketplace add PostHog/claude-code-share-plugin"
    echo "   /plugin install share-sessions@claude-code-share-plugin"
    echo ""
    echo "3. Test with: /share"
    echo ""
    echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
    exit 0
fi

# Install plugin using Claude CLI
echo "🔌 Installing plugin via Claude CLI..."
echo ""

# Add marketplace
echo "Adding marketplace..."
if claude plugin marketplace add PostHog/claude-code-share-plugin 2>&1; then
    echo "✅ Marketplace added"
else
    # Check if it's already added (non-fatal)
    if claude plugin marketplace list 2>&1 | grep -q "claude-code-share-plugin"; then
        echo "✅ Marketplace already added"
    else
        echo "❌ Failed to add marketplace"
        echo "You can add it manually with:"
        echo "  claude plugin marketplace add PostHog/claude-code-share-plugin"
    fi
fi

echo ""

# Install plugin
echo "Installing share-sessions plugin..."
if claude plugin install share-sessions@claude-code-share-plugin 2>&1; then
    echo "✅ Plugin installed successfully!"
else
    echo "⚠️  Plugin installation encountered an issue"
    echo "You can try installing manually with:"
    echo "  claude plugin install share-sessions@claude-code-share-plugin"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "1. Open a new terminal (to load environment variables)"
echo "2. Start Claude Code and test with: /share"
echo ""
echo "💡 Tip: Your sessions will be saved to: $SESSIONS_REPO/$BASE_PATH/$GITHUB_USERNAME/"
echo ""
echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
