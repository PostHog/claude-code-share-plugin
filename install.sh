#!/bin/bash
# One-liner installer for Claude Code Share Plugin
# Usage: bash install.sh --claude-share-repo owner/repo
# Or: bash install.sh owner/repo (positional)

set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --claude-share-repo)
            export CLAUDE_SHARE_REPO="$2"
            shift 2
            ;;
        --claude-share-username)
            export CLAUDE_SHARE_USERNAME="$2"
            shift 2
            ;;
        --claude-share-branch)
            export CLAUDE_SHARE_BRANCH="$2"
            shift 2
            ;;
        --claude-share-base-path)
            export CLAUDE_SHARE_BASE_PATH="$2"
            shift 2
            ;;
        --help|-h)
            echo "Claude Code Share Plugin Installer"
            echo ""
            echo "Usage:"
            echo "  bash install.sh --claude-share-repo owner/repo"
            echo "  bash install.sh owner/repo"
            echo ""
            echo "Options:"
            echo "  --claude-share-repo REPO       Repository for sessions (required)"
            echo "  --claude-share-username USER   GitHub username (auto-detected if not set)"
            echo "  --claude-share-branch BRANCH   Branch to push to (default: main)"
            echo "  --claude-share-base-path PATH  Base path in repo (default: sessions)"
            echo "  --help, -h                     Show this help message"
            echo ""
            echo "Examples:"
            echo "  bash install.sh --claude-share-repo myuser/sessions"
            echo "  bash install.sh posthog/claude-sessions"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            # Positional argument - treat as repo
            if [[ -z "$CLAUDE_SHARE_REPO" ]]; then
                export CLAUDE_SHARE_REPO="$1"
            fi
            shift
            ;;
    esac
done

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
    # Check if we can prompt (stdin is a terminal)
    if [[ -t 0 ]]; then
        echo "📝 Configuration needed"
        echo ""
        read -p "Enter repository for sessions (format: owner/repo): " CLAUDE_SHARE_REPO
        echo ""

        if [[ -z "$CLAUDE_SHARE_REPO" ]]; then
            echo "❌ Error: Repository is required"
            exit 1
        fi

        export CLAUDE_SHARE_REPO
    else
        echo ""
        echo "❌ Error: CLAUDE_SHARE_REPO not set"
        echo ""
        echo "Please run the installer with your repository as an argument:"
        echo "  curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | bash -s owner/repo"
        echo ""
        echo "Example:"
        echo "  curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | bash -s myuser/sessions"
        exit 1
    fi
fi

if [[ -n "$CLAUDE_SHARE_REPO" ]]; then
    echo "✅ Configuration found"
    echo "   Repo: $CLAUDE_SHARE_REPO"
    echo "   Username: $CLAUDE_SHARE_USERNAME"
    echo ""
    # Set defaults if not provided
    export CLAUDE_SHARE_BRANCH="${CLAUDE_SHARE_BRANCH:-main}"
    export CLAUDE_SHARE_BASE_PATH="${CLAUDE_SHARE_BASE_PATH:-sessions}"

    echo "📋 Add these to your shell profile (~/.zshrc, ~/.bashrc) to persist:"
    echo ""
    echo "  export CLAUDE_SHARE_REPO=\"$CLAUDE_SHARE_REPO\""
    echo "  export CLAUDE_SHARE_USERNAME=\"$CLAUDE_SHARE_USERNAME\""
    echo "  export CLAUDE_SHARE_BRANCH=\"$CLAUDE_SHARE_BRANCH\""
    echo "  export CLAUDE_SHARE_BASE_PATH=\"$CLAUDE_SHARE_BASE_PATH\""
    echo ""
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
echo "🚀 Start Claude Code and test with: /share"
echo ""
echo "📚 Documentation: https://github.com/PostHog/claude-code-share-plugin"
