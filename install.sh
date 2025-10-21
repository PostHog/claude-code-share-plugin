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
        --help|-h)
            echo "Claude Code Share Plugin Installer"
            echo ""
            echo "Usage:"
            echo "  bash install.sh --claude-share-repo owner/repo"
            echo ""
            echo "Example:"
            echo "  bash install.sh --claude-share-repo posthog/claude-sessions"
            echo ""
            echo "Your GitHub username will be auto-detected from gh CLI"
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

echo "» Installing Claude Code Share Plugin..."
# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "✗ Error: GitHub CLI (gh) is not installed."
    echo "  Install it from: https://cli.github.com/"
    exit 1
fi
# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "✗ Error: GitHub CLI is not authenticated."
    echo "  Run: gh auth login"
    exit 1
fi
echo "✓ GitHub CLI is installed and authenticated"
# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "✗ Error: Claude CLI not found in PATH"
    echo "  Please install Claude Code first, then run:"
    echo "  claude plugin marketplace add PostHog/claude-code-share-plugin"
    echo "  claude plugin install share-sessions@claude-code-share-plugin"
    echo "  Documentation: https://github.com/PostHog/claude-code-share-plugin"
    exit 1
fi
echo "✓ Claude CLI found"

# Get GitHub username from gh CLI if not set
if [[ -z "$CLAUDE_SHARE_USERNAME" ]]; then
    GH_USERNAME=$(gh api user --jq .login 2>/dev/null)
    if [[ -n "$GH_USERNAME" ]]; then
        export CLAUDE_SHARE_USERNAME="$GH_USERNAME"
        echo "✓ Detected GitHub username: $GH_USERNAME"
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
    echo "✓ Configuration found"
    echo "  Repo: $CLAUDE_SHARE_REPO"
    echo "  Username: $CLAUDE_SHARE_USERNAME (auto-detected)"
    # Write config to file
    echo "» Saving configuration to ~/.claude/share-plugin-config.json"
    mkdir -p ~/.claude
    cat > ~/.claude/share-plugin-config.json <<EOF
{
  "repo": "$CLAUDE_SHARE_REPO"
}
EOF
    echo "✓ Configuration saved"
fi
# Install plugin using Claude CLI
echo "» Installing plugin via Claude CLI..."

# Uninstall old versions if they exist
echo "» Checking for existing installations..."
if claude plugin uninstall share-sessions 2>&1 | grep -q "Successfully uninstalled"; then
    echo "✓ Removed old share-sessions plugin"
fi
if claude plugin uninstall share 2>&1 | grep -q "Successfully uninstalled"; then
    echo "✓ Removed existing share plugin"
fi
# Check if marketplace already exists
if claude plugin marketplace list 2>&1 | grep -q "claude-code-share-plugin"; then
    claude plugin marketplace update claude-code-share-plugin 2>&1 > /dev/null
    echo "✓ Marketplace updated"
else
    if claude plugin marketplace add PostHog/claude-code-share-plugin 2>&1; then
        echo "✓ Marketplace added"
    else
        echo "✗ Failed to add marketplace"
        exit 1
    fi
fi
# Install plugin
if claude plugin install share@claude-code-share-plugin 2>&1; then
    echo "✓ Plugin installed successfully"
else
    echo "✗ Failed to install plugin"
    exit 1
fi
echo "✓ Installation complete"
echo "  Sessions will be saved to: $CLAUDE_SHARE_REPO/sessions/$CLAUDE_SHARE_USERNAME/"
echo "  Test with: /share"
echo "  Documentation: https://github.com/PostHog/claude-code-share-plugin"
