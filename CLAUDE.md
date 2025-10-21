# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that converts JSONL session logs into readable markdown and publishes them to GitHub repositories. The plugin provides a `/share` slash command that executes a Python script to handle the conversion and upload process.

## Key Architecture

### Plugin Structure

The plugin follows the standard Claude Code plugin architecture:

- **`.claude-plugin/plugin.json`**: Plugin metadata (name, version, author)
- **`commands/share.md`**: Slash command definition that invokes the Python script
- **`scripts/share_session.py`**: Core Python script that handles all functionality
- **`install.sh`**: Automated installer that configures the plugin and saves settings

### Core Components

**Session Log Discovery** (`find_latest_session_log()` in scripts/share_session.py:31-56):
- Converts current working directory to Claude project directory format (e.g., `/Users/foo/project` → `-Users-foo-project`)
- Searches `~/.claude/projects/{project_dir_name}/*.jsonl` for session files
- Falls back to searching all projects if current project directory not found
- Returns most recently modified JSONL file

**Configuration System** (`get_config()` in scripts/share_session.py:58-86):
- Priority: `~/.claude/share-plugin-config.json` → `CLAUDE_SHARE_REPO` env var
- Auto-detects GitHub username via `gh api user --jq .login`
- Returns config dict with: repo, username, branch (defaults to "main"), base_path (defaults to "sessions")

**JSONL to Markdown Conversion** (`convert_jsonl_to_markdown()` in scripts/share_session.py:108-213):
- Parses JSONL entries where each line has `{message: {role, content}}`
- Filters out `/share` command artifacts to avoid recursion in shared sessions
- Formats user messages as `## User` sections
- Formats assistant messages as `## Claude` sections
- Collapses tool calls in `<details>` tags with tool name and JSON input
- Skip logic prevents share-related commands/responses from appearing in output

**GitHub Push Process** (`push_to_github()` in scripts/share_session.py:216-293):
- Clones target repo to `/tmp/claude-share-temp`
- Creates directory structure: `{base_path}/{username}/{timestamp}-{description}.md`
- Commits with message: "Add session: {description}" or "Add session {timestamp}"
- Pushes to configured branch and returns GitHub blob URL

### Installation Process

The `install.sh` script:
1. Validates `gh` CLI is installed and authenticated
2. Auto-detects GitHub username from `gh api user`
3. Prompts for or accepts `CLAUDE_SHARE_REPO` as argument
4. Saves configuration to `~/.claude/share-plugin-config.json` (not env vars)
5. Uninstalls old plugin versions (`share-sessions`, `share`)
6. Adds/updates marketplace: `claude plugin marketplace add PostHog/claude-code-share-plugin`
7. Installs plugin: `claude plugin install share@claude-code-share-plugin`

## Development Commands

### Testing the Plugin Locally

```bash
# Install from local directory
/plugin marketplace add ~/path/to/claude-code-share-plugin
/plugin install share@claude-code-share-plugin

# Reinstall after making changes
/plugin uninstall share
/plugin install share@claude-code-share-plugin

# Test the command
/share test description
```

### Running the Python Script Directly

```bash
# With description
python3 scripts/share_session.py test session description

# Without description
python3 scripts/share_session.py
```

### Configuration for Testing

```bash
# Option 1: Use config file (preferred)
cat > ~/.claude/share-plugin-config.json <<EOF
{
  "repo": "test-owner/test-repo"
}
EOF

# Option 2: Use environment variable (overrides config file)
export CLAUDE_SHARE_REPO="test-owner/test-repo"
```

## Important Implementation Details

### Session Log Location

Session logs are stored in `~/.claude/projects/{escaped-cwd}/*.jsonl` where the current working directory path has forward slashes replaced with hyphens (e.g., `/Users/foo/my-project` becomes `-Users-foo-my-project`).

### Filtering Share Command Artifacts

When converting JSONL to markdown, the script filters out messages containing:
- `/share` command text
- `share_session.py` script execution
- `claude-code-share-plugin` path references
- Share-related tool calls

This prevents infinite recursion where sharing a session about sharing creates nested share commands in the output.

### Git Operations Workflow

The script performs git operations in a temporary directory (`/tmp/claude-share-temp`) to avoid affecting the user's current working directory or git state. After pushing, the temp directory is cleaned up.

### Commit Message Conventions

This project uses conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style/formatting
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks
