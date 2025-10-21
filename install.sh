#!/bin/bash
# One-liner installer for Claude Code Share Plugin
# Usage: bash install.sh --claude-share-repo owner/repo
# Or: bash install.sh owner/repo (positional)

set -e

# Colors
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GRAY='\033[0;90m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    BLUE=''
    GRAY=''
    NC=''
fi

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

printf "%b\n" "${BLUE}» Installing Claude Code Share Plugin...${NC}"
# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    printf "%b\n" "${RED}✗ Error: GitHub CLI (gh) is not installed.${NC}"
    printf "%b\n" "${GRAY}  Install it from: https://cli.github.com/${NC}"
    exit 1
fi
# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    printf "%b\n" "${RED}✗ Error: GitHub CLI is not authenticated.${NC}"
    printf "%b\n" "${GRAY}  Run: gh auth login${NC}"
    exit 1
fi
printf "%b\n" "${GREEN}✓ GitHub CLI is installed and authenticated${NC}"
# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    printf "%b\n" "${RED}✗ Error: Claude CLI not found in PATH${NC}"
    printf "%b\n" "${GRAY}  Please install Claude Code first, then run:${NC}"
    printf "%b\n" "${GRAY}  claude plugin marketplace add PostHog/claude-code-share-plugin${NC}"
    printf "%b\n" "${GRAY}  claude plugin install share-sessions@claude-code-share-plugin${NC}"
    printf "%b\n" "${GRAY}  Documentation: https://github.com/PostHog/claude-code-share-plugin${NC}"
    exit 1
fi
printf "%b\n" "${GREEN}✓ Claude CLI found${NC}"

# Get GitHub username from gh CLI if not set
if [[ -z "$CLAUDE_SHARE_USERNAME" ]]; then
    GH_USERNAME=$(gh api user --jq .login 2>/dev/null)
    if [[ -n "$GH_USERNAME" ]]; then
        export CLAUDE_SHARE_USERNAME="$GH_USERNAME"
        printf "%b\n" "${GREEN}✓ Detected GitHub username: $GH_USERNAME${NC}"
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
    printf "%b\n" "${GREEN}✓ Configuration found${NC}"
    printf "%b\n" "${GRAY}  Repo: $CLAUDE_SHARE_REPO${NC}"
    printf "%b\n" "${GRAY}  Username: $CLAUDE_SHARE_USERNAME (auto-detected)${NC}"
    # Write config to file
    printf "%b\n" "${BLUE}» Saving configuration to ~/.claude/share-plugin-config.json${NC}"
    mkdir -p ~/.claude
    cat > ~/.claude/share-plugin-config.json <<EOF
{
  "repo": "$CLAUDE_SHARE_REPO"
}
EOF
    printf "%b\n" "${GREEN}✓ Configuration saved${NC}"
fi
# Install plugin using Claude CLI
printf "%b\n" "${BLUE}» Installing plugin via Claude CLI...${NC}"

# Uninstall old versions if they exist
printf "%b\n" "${BLUE}» Checking for existing installations...${NC}"
if claude plugin uninstall share-sessions 2>&1 | grep -q "Successfully uninstalled"; then
    printf "%b\n" "${GREEN}✓ Removed old share-sessions plugin${NC}"
fi
if claude plugin uninstall share 2>&1 | grep -q "Successfully uninstalled"; then
    printf "%b\n" "${GREEN}✓ Removed existing share plugin${NC}"
fi
# Check if marketplace already exists
if claude plugin marketplace list 2>&1 | grep -q "claude-code-share-plugin"; then
    claude plugin marketplace update claude-code-share-plugin 2>&1 > /dev/null
    printf "%b\n" "${GREEN}✓ Marketplace updated${NC}"
else
    if claude plugin marketplace add PostHog/claude-code-share-plugin 2>&1; then
        printf "%b\n" "${GREEN}✓ Marketplace added${NC}"
    else
        printf "%b\n" "${RED}✗ Failed to add marketplace${NC}"
        exit 1
    fi
fi
# Install plugin
if claude plugin install share@claude-code-share-plugin 2>&1; then
    printf "%b\n" "${GREEN}✓ Plugin installed successfully${NC}"
else
    printf "%b\n" "${RED}✗ Failed to install plugin${NC}"
    exit 1
fi
printf "%b\n" "${GREEN}✓ Installation complete${NC}"
printf "%b\n" "${GRAY}  Sessions will be saved to: $CLAUDE_SHARE_REPO/sessions/$CLAUDE_SHARE_USERNAME/${NC}"
printf "%b\n" "${GRAY}  Test with: /share${NC}"
printf "%b\n" "${GRAY}  Documentation: https://github.com/PostHog/claude-code-share-plugin${NC}"
