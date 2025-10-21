# Share Session Command

Share the current Claude Code session to a GitHub repository as markdown.

## Usage

```
/share [description]
```

## Examples

```
/share
/share fixing authentication bug
/share adding new feature
```

## Implementation

Find and execute the share script:

```bash
find ~/.claude/plugins -name "share_session.py" -path "*/claude-code-share-plugin/*" 2>/dev/null | head -1 | xargs -I {} python3 {} $ARGUMENTS
```
