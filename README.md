# Claude Code Session Sharing Plugin

A Claude Code plugin that saves and shares your coding sessions to GitHub repositories in readable markdown format.

## Features

- 📝 Converts JSONL session logs to clean, readable markdown
- 🔄 Automatically commits and pushes to any GitHub repository
- 👤 Organizes sessions by username in configurable directory structure
- 🎯 Supports optional session descriptions
- 🔧 Collapses tool usage details by default for cleaner reading
- ⚙️ Fully configurable via environment variables

## Prerequisites

- Python 3.6+
- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- A GitHub repository to store sessions (public or private)

## Installation

### Quick Install (Recommended)

**One-liner installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | bash -s -- --claude-share-repo your-username/sessions
```

Replace `your-username/sessions` with your sessions repository. Your GitHub username is auto-detected from `gh` CLI!

**Alternative (download first):**
```bash
curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh -o /tmp/claude-share-install.sh && bash /tmp/claude-share-install.sh --claude-share-repo your-username/sessions
```

**What it does:**
- Checks prerequisites (`gh` CLI and `claude` CLI)
- Auto-detects your GitHub username
- Installs the plugin marketplace and plugin
- Shows env vars to add to your shell profile for persistence

### Manual Installation

#### Option 1: Install from GitHub

In Claude Code, run:

```
/plugin marketplace add PostHog/claude-code-share-plugin
/plugin install share-sessions@claude-code-share-plugin
```

#### Option 2: Install locally

Clone the repository:

```bash
gh repo clone PostHog/claude-code-share-plugin ~/claude-plugins/claude-code-share-plugin
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/claude-code-share-plugin
/plugin install share-sessions@claude-code-share-plugin
```

### Configure environment variables (if not using Quick Install)

If you didn't use the quick installer, add these to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
# Required: Target repository (format: owner/repo-name)
export CLAUDE_SHARE_REPO="your-username/your-sessions-repo"

# Optional: Your GitHub username (auto-detected from gh CLI if not set)
export CLAUDE_SHARE_USERNAME="your-github-username"

# Optional: Branch to push to (default: main)
export CLAUDE_SHARE_BRANCH="main"

# Optional: Base path in repo (default: sessions)
export CLAUDE_SHARE_BASE_PATH="sessions"
```

Reload your shell:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### Team/Project Configuration (Optional)

For automatic plugin installation across your team, add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-share-plugin": {
      "source": {
        "source": "github",
        "repo": "PostHog/claude-code-share-plugin"
      }
    }
  },
  "enabledPlugins": [
    "share-sessions@claude-code-share-plugin"
  ]
}
```

When team members trust the repository, Claude Code will automatically install the marketplace and plugin.

## Usage

### Basic usage

Share the current session with no description:

```
/share
```

### With description

Share with a descriptive name:

```
/share fixing authentication bug
```

This creates a file like: `20251021-142530-fixing-authentication-bug.md`

### Output structure

Sessions are organized as:

```
your-sessions-repo/
└── sessions/           # Configurable via CLAUDE_SHARE_BASE_PATH
    └── username/       # Your CLAUDE_SHARE_USERNAME
        ├── 20251021-142530-fixing-auth.md
        ├── 20251021-153245-adding-tests.md
        └── ...
```

### Example markdown output

```markdown
# Claude Code Session

**Date:** 2025-10-21 14:25:30

---

## 👤 User

Can you help me fix the authentication bug?

## 🤖 Assistant

I'll help you investigate the authentication issue. Let me first check the relevant files.

<details>
<summary>🔧 Tool: read_any_files</summary>

```json
{
  "files": [
    {
      "path": "/src/auth/login.py"
    }
  ]
}
```
</details>

...
```

## Configuration Options

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CLAUDE_SHARE_REPO` | ✅ | - | Target repo (format: `owner/repo`) |
| `CLAUDE_SHARE_USERNAME` | ✅ | - | Your GitHub username |
| `CLAUDE_SHARE_BRANCH` | ❌ | `main` | Branch to commit to |
| `CLAUDE_SHARE_BASE_PATH` | ❌ | `sessions` | Base directory in repo |

## Troubleshooting

### "Error: CLAUDE_SHARE_REPO environment variable not set"

Make sure you've exported the required environment variables and reloaded your shell.

### "Error cloning repository"

Ensure:
1. The `gh` CLI is installed: `gh --version`
2. You're authenticated: `gh auth status`
3. You have access to the target repository
4. The repository exists

### "Error pushing to GitHub"

Check that:
1. You have write access to the repository
2. The branch exists (or create it first)
3. Your authentication hasn't expired: `gh auth refresh`

## Development

To modify the plugin:

1. Edit files in this directory
2. Uninstall the old version: `/plugin uninstall share-sessions`
3. Reinstall: `/plugin install ./`
4. Test your changes

## How It Works

1. Reads the current Claude Code session log (JSONL format)
2. Parses each message (user/assistant/tool calls)
3. Converts to readable markdown with:
   - User messages with 👤 prefix
   - Assistant responses with 🤖 prefix
   - Tool usage in collapsible `<details>` sections
4. Clones target repo to `/tmp/claude-share-temp`
5. Creates session file with timestamp and description
6. Commits and pushes to GitHub
7. Provides direct link to view the session

## Privacy & Security

- Session logs may contain sensitive information from your codebase
- Consider using a **private repository** for session storage
- Review the generated markdown before sharing links publicly
- The plugin uses `gh` CLI which respects your existing GitHub authentication

## License

MIT

## Credits

Inspired by the PostHog team's internal `/share` command ([PR #39723](https://github.com/PostHog/posthog/pull/39723)).
