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

Run the Python script to convert the session and push to GitHub:

```bash
python3 {{PLUGIN_DIR}}/scripts/share_session.py {{ARGS}}
```
