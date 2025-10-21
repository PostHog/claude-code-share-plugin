---
description: Share the current Claude Code session to GitHub as markdown
allowed-tools: Bash(find:*), Bash(python3:*)
---

```bash
find ~/.claude/plugins -name "share_session.py" -path "*/claude-code-share-plugin/*" 2>/dev/null | head -1 | xargs -I {} python3 {} $ARGUMENTS
```
