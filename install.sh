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

# Get GitHub username from gh CLI if not set
if [[ -z "$CLAUDE_SHARE_USERNAME" ]]; then
    GH_USERNAME=$(gh api user --jq .login 2>/dev/null)
    if [[ -n "$GH_USERNAME" ]]; then
        export CLAUDE_SHARE_USERNAME="$GH_USERNAME"
        echo "✅ Detected GitHub username: $GH_USERNAME"
    fi
fi

# Check if config is already set via environment variables
if [[ -z "$CLAUDE_SHARE_REPO" ]]; then
    echo ""
    echo "📝 Configuration needed"
    echo ""
    echo "💡 Tip: You can set this before running the installer:"
    echo "  CLAUDE_SHARE_REPO=user/repo curl ... | bash"
    echo ""
    read -p "Enter repository for sessions (format: owner/repo): " SESSIONS_REPO
    read -p "Enter branch name [main]: " BRANCH_NAME
    BRANCH_NAME=${BRANCH_NAME:-main}
    read -p "Enter base path in repo [sessions]: " BASE_PATH
    BASE_PATH=${BASE_PATH:-sessions}

    export CLAUDE_SHARE_REPO="$SESSIONS_REPO"
    export CLAUDE_SHARE_BRANCH="$BRANCH_NAME"
    export CLAUDE_SHARE_BASE_PATH="$BASE_PATH"

    echo ""
    echo "📋 To use the plugin, add these to your shell profile (~/.zshrc, ~/.bashrc):"
    echo ""
    echo "  export CLAUDE_SHARE_REPO=\"$SESSIONS_REPO\""
    echo "  export CLAUDE_SHARE_USERNAME=\"$CLAUDE_SHARE_USERNAME\""
    echo "  export CLAUDE_SHARE_BRANCH=\"$BRANCH_NAME\""
    echo "  export CLAUDE_SHARE_BASE_PATH=\"$BASE_PATH\""
    echo ""
    read -p "Press Enter to continue with plugin installation..."
else
    echo "✅ Configuration found"
    echo "   Repo: $CLAUDE_SHARE_REPO"
    echo "   Username: $CLAUDE_SHARE_USERNAME"
    # Set defaults if not provided
    export CLAUDE_SHARE_BRANCH="${CLAUDE_SHARE_BRANCH:-main}"
    export CLAUDE_SHARE_BASE_PATH="${CLAUDE_SHARE_BASE_PATH:-sessions}"
fi

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
echo "💡 Your sessions will be saved to: $CLAUDE_SHARE_REPO/$CLAUDE_SHARE_BASE_PATH/$CLAUDE_SHARE_USERNAME/"
echo ""
if [[ -z "$SESSIONS_REPO" ]]; then
    # Config was provided via env vars
    echo "🚀 Test with: /share"
else
    # Config was prompted - remind to add to shell
    echo "⚠️  IMPORTANT: Add the environment variables shown above to your shell profile"
    echo "   Then reload: source ~/.zshrc (or ~/.bashrc)"
    echo ""
    echo "🚀 After reloading your shell, test with: /share"
fi
echo ""
echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
