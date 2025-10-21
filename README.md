# Claude Code Session Sharing Plugin

A Claude Code plugin that saves and shares your coding sessions to GitHub repositories in readable markdown format.

## Features

- Converts JSONL session logs to clean, readable markdown
- Automatically commits and pushes to any GitHub repository
- Organizes sessions by username in configurable directory structure
- Supports optional session descriptions
- Collapses tool usage details by default for cleaner reading
- Fully configurable via environment variables

## Prerequisites

- Python 3.6+
- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- A GitHub repository to store sessions (public or private)

## Installation

### Quick Install (Recommended)

**One-liner installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | \
  bash -s -- --claude-share-repo repo-owner/repo-name
```

Replace `repo-owner/repo-name` with your sessions repository.

**What gets auto-detected:**
- GitHub username (from `gh` CLI)
- Current session log (from `~/.claude/projects/` based on working directory)
- Branch (defaults to `main`)
- Path (defaults to `sessions`)

**Configuration is saved automatically** to `~/.claude/share-plugin-config.json` during installation - no environment variables needed!

### Manual Installation

#### Option 1: Install from GitHub

In Claude Code, run:

```
/plugin marketplace add PostHog/claude-code-share-plugin
/plugin install share@claude-code-share-plugin
```

#### Option 2: Install locally

Clone the repository:

```bash
gh repo clone PostHog/claude-code-share-plugin ~/claude-plugins/claude-code-share-plugin
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/claude-code-share-plugin
/plugin install share@claude-code-share-plugin
```

### Manual Configuration (Optional)

The Quick Install automatically saves configuration to `~/.claude/share-plugin-config.json`.

If you need to change the repository later, you can either:

1. **Re-run the installer** with a new repo
2. **Edit the config file** directly:
   ```bash
   cat > ~/.claude/share-plugin-config.json <<EOF
   {
     "repo": "new-owner/new-repo"
   }
   EOF
   ```
3. **Use environment variable** (takes precedence over config file):
   ```bash
   export CLAUDE_SHARE_REPO="repo-owner/repo-name"
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
    "share@claude-code-share-plugin"
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
└── sessions/
    └── username/       # Auto-detected from gh CLI
        ├── 20251021-142530-fixing-auth.md
        ├── 20251021-153245-adding-tests.md
        └── ...
```

### Example markdown output

```markdown
# Claude Code Session

**Date:** 2025-10-21 14:25:30

---

## User

Can you help me fix the authentication bug?

## Claude

I'll help you investigate the authentication issue. Let me first check the relevant files.

<details>
<summary>Tool: read_any_files</summary>

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

## Configuration

| What | How |
|------|-----|
| **Configured during install** | Repository saved to `~/.claude/share-plugin-config.json` |
| **Auto-detected** | Username (from `gh` CLI) |
| **Auto-detected** | Session log (from `~/.claude/projects/` based on working directory) |
| **Defaults** | Branch: `main`, Path: `sessions` |

## Troubleshooting

### "Error: Repository not configured"

The plugin needs to know which GitHub repository to use. Run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/PostHog/claude-code-share-plugin/main/install.sh | \
  bash -s -- repo-owner/repo-name
```

Or create the config file manually:

```bash
cat > ~/.claude/share-plugin-config.json <<EOF
{
  "repo": "repo-owner/repo-name"
}
EOF
```

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
2. Uninstall the old version: `/plugin uninstall share`
3. Reinstall: `/plugin install share@claude-code-share-plugin`
4. Test your changes

## How It Works

1. Reads the current Claude Code session log (JSONL format)
2. Parses each message (user/assistant/tool calls)
3. Converts to readable markdown with:
   - User messages
   - Claude responses
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
