#!/usr/bin/env python3
"""
Claude Code session sharing script.
Converts JSONL session logs to markdown and pushes to GitHub.
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


def get_github_username() -> str:
    """Get GitHub username from gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "api", "user", "--jq", ".login"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def find_latest_session_log() -> Optional[str]:
    """Find the most recent Claude Code session log."""
    # Look for session logs in Claude directory
    claude_dir = Path.home() / ".claude" / "sessions"
    if not claude_dir.exists():
        return None

    # Find the most recently modified .jsonl file
    jsonl_files = list(claude_dir.glob("**/*.jsonl"))
    if not jsonl_files:
        return None

    # Sort by modification time, newest first
    jsonl_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return str(jsonl_files[0])


def get_config() -> dict:
    """Get configuration with auto-detection and defaults."""
    # Auto-detect username from gh CLI
    username = get_github_username()
    if not username:
        username = "unknown-user"

    return {
        "repo": os.environ.get("CLAUDE_SHARE_REPO", ""),
        "username": username,
        "branch": "main",
        "base_path": "sessions",
    }


def sanitize_filename(text: str) -> str:
    """Convert text to safe filename."""
    text = text.lower()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    text = text.strip('-')
    return text[:50] if text else "session"


def format_tool_call(tool_name: str, tool_input: dict) -> str:
    """Format a tool call as markdown."""
    input_str = json.dumps(tool_input, indent=2)
    return f"""<details>
<summary>🔧 Tool: {tool_name}</summary>

```json
{input_str}
```
</details>"""


def convert_jsonl_to_markdown(jsonl_path: str) -> str:
    """Convert JSONL session log to markdown format."""
    markdown_lines = [
        "# Claude Code Session",
        "",
        f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "---",
        ""
    ]
    
    with open(jsonl_path, 'r') as f:
        for line in f:
            if not line.strip():
                continue
                
            try:
                entry = json.loads(line)
                role = entry.get('role', '')
                
                if role == 'user':
                    content = entry.get('content', '')
                    if isinstance(content, list):
                        # Handle multipart content
                        for item in content:
                            if isinstance(item, dict) and item.get('type') == 'text':
                                markdown_lines.extend([
                                    "## 👤 User",
                                    "",
                                    item.get('text', ''),
                                    "",
                                ])
                    else:
                        markdown_lines.extend([
                            "## 👤 User",
                            "",
                            content,
                            "",
                        ])
                
                elif role == 'assistant':
                    content = entry.get('content', [])
                    if isinstance(content, str):
                        markdown_lines.extend([
                            "## 🤖 Assistant",
                            "",
                            content,
                            "",
                        ])
                    elif isinstance(content, list):
                        has_text = False
                        tool_calls = []
                        
                        for item in content:
                            if isinstance(item, dict):
                                if item.get('type') == 'text':
                                    if not has_text:
                                        markdown_lines.extend(["## 🤖 Assistant", ""])
                                        has_text = True
                                    markdown_lines.extend([
                                        item.get('text', ''),
                                        "",
                                    ])
                                elif item.get('type') == 'tool_use':
                                    tool_calls.append({
                                        'name': item.get('name', 'unknown'),
                                        'input': item.get('input', {})
                                    })
                        
                        # Add tool calls in collapsed sections
                        if tool_calls:
                            for tool in tool_calls:
                                markdown_lines.append(format_tool_call(tool['name'], tool['input']))
                                markdown_lines.append("")
            
            except json.JSONDecodeError:
                continue
    
    return "\n".join(markdown_lines)


def push_to_github(markdown_content: str, description: Optional[str], config: dict) -> bool:
    """Push markdown content to GitHub repository."""
    repo = config["repo"]
    username = config["username"]
    branch = config["branch"]
    base_path = config["base_path"]
    
    if not repo:
        print("Error: CLAUDE_SHARE_REPO environment variable not set")
        print("Example: export CLAUDE_SHARE_REPO='owner/repo-name'")
        return False
    
    if not username:
        print("Error: CLAUDE_SHARE_USERNAME environment variable not set")
        print("Example: export CLAUDE_SHARE_USERNAME='your-github-username'")
        return False
    
    # Create filename
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    desc_part = f"-{sanitize_filename(description)}" if description else ""
    filename = f"{timestamp}{desc_part}.md"
    
    # Create file path
    file_path = f"{base_path}/{username}/{filename}"
    
    # Clone repo to temp directory
    temp_dir = Path("/tmp/claude-share-temp")
    if temp_dir.exists():
        subprocess.run(["rm", "-rf", str(temp_dir)], check=True)
    
    print(f"Cloning {repo}...")
    result = subprocess.run(
        ["gh", "repo", "clone", repo, str(temp_dir)],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"Error cloning repository: {result.stderr}")
        return False
    
    # Create directory structure
    target_dir = temp_dir / base_path / username
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Write markdown file
    target_file = target_dir / filename
    target_file.write_text(markdown_content)
    
    # Git operations
    os.chdir(temp_dir)
    
    subprocess.run(["git", "add", file_path], check=True)
    
    commit_msg = f"Add session: {description}" if description else f"Add session {timestamp}"
    subprocess.run(["git", "commit", "-m", commit_msg], check=True)
    
    print(f"Pushing to {repo}...")
    result = subprocess.run(
        ["git", "push", "origin", branch],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"Error pushing to GitHub: {result.stderr}")
        return False
    
    # Construct GitHub URL
    github_url = f"https://github.com/{repo}/blob/{branch}/{file_path}"
    print(f"\n✅ Session shared successfully!")
    print(f"📄 View at: {github_url}")
    
    # Cleanup
    os.chdir("/")
    subprocess.run(["rm", "-rf", str(temp_dir)], check=True)
    
    return True


def main():
    """Main entry point for share command."""
    # Get description from command arguments
    description = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else None

    # Find the latest session log
    session_log = find_latest_session_log()
    if not session_log:
        print("Error: Could not find Claude Code session log")
        print("Expected location: ~/.claude/sessions/**/*.jsonl")
        return 1

    print(f"📄 Found session: {Path(session_log).name}")
    print()

    # Get configuration
    config = get_config()

    if not config["repo"]:
        print("Error: CLAUDE_SHARE_REPO not set")
        print("Set it with: export CLAUDE_SHARE_REPO=owner/repo")
        return 1

    # Convert JSONL to markdown
    print("Converting session to markdown...")
    markdown_content = convert_jsonl_to_markdown(session_log)

    # Push to GitHub
    success = push_to_github(markdown_content, description, config)

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
