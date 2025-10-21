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

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ Error: Claude CLI not found in PATH"
    echo ""
    echo "Please install Claude Code first, then run:"
    echo "  claude plugin marketplace add PostHog/claude-code-share-plugin"
    echo "  claude plugin install share-sessions@claude-code-share-plugin"
    echo ""
    echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
    exit 1
fi

echo "✅ Claude CLI found"
echo ""

# Prompt for configuration
echo "📝 Configuration setup"
echo "You'll need to add these to your shell profile (~/.zshrc, ~/.bashrc, etc.)"
echo ""
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter repository for sessions (format: owner/repo): " SESSIONS_REPO
read -p "Enter branch name [main]: " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-main}
read -p "Enter base path in repo [sessions]: " BASE_PATH
BASE_PATH=${BASE_PATH:-sessions}

echo ""
echo "📋 Add these lines to your shell profile:"
echo ""
echo "  export CLAUDE_SHARE_REPO=\"$SESSIONS_REPO\""
echo "  export CLAUDE_SHARE_USERNAME=\"$GITHUB_USERNAME\""
echo "  export CLAUDE_SHARE_BRANCH=\"$BRANCH_NAME\""
echo "  export CLAUDE_SHARE_BASE_PATH=\"$BASE_PATH\""
echo ""
read -p "Press Enter to continue with plugin installation..."

# Install plugin using Claude CLI
echo ""
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
        exit 1
    fi
fi

echo ""

# Install plugin
echo "Installing share-sessions plugin..."
if claude plugin install share-sessions@claude-code-share-plugin 2>&1; then
    echo "✅ Plugin installed successfully!"
else
    echo "⚠️  Plugin may already be installed"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "⚠️  IMPORTANT: Add the environment variables above to your shell profile"
echo "   Then reload: source ~/.zshrc (or ~/.bashrc)"
echo ""
echo "💡 Your sessions will be saved to: $SESSIONS_REPO/$BASE_PATH/$GITHUB_USERNAME/"
echo ""
echo "🚀 After reloading your shell, test with: /share"
echo ""
echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
