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
SCRIPT_PATH=$(find ~/.claude/plugins -name "share_session.py" -path "*/claude-code-share-plugin/*" 2>/dev/null | head -1)
if [ -z "$SCRIPT_PATH" ]; then
  echo "Error: share_session.py not found in plugin directory"
  exit 1
fi
python3 "$SCRIPT_PATH" $ARGUMENTS
```
