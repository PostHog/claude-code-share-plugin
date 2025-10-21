---
description: Share the current Claude Code session to GitHub as markdown
argument-hint: [optional description]
allowed-tools: Bash(find ~/.claude/plugins -name "share_session.py":*), Bash(python3 * share_session.py:*)
---

Execute this command to share the session:

```bash
find ~/.claude/plugins -name "share_session.py" -path "*/claude-code-share-plugin/*" 2>/dev/null | head -1 | xargs -I {} python3 {} $ARGUMENTS
```
