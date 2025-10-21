# Contributing to Claude Code Share Plugin

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Development Setup

1. Fork and clone the repository:
   ```bash
   gh repo fork PostHog/claude-code-share-plugin --clone
   cd claude-code-share-plugin
   ```

2. Install the plugin locally for testing:
   ```bash
   # In Claude Code
   /plugin marketplace add ~/path/to/claude-code-share-plugin
   /plugin install share-sessions@claude-code-share-plugin
   ```

3. Set up environment variables for testing:
   ```bash
   export CLAUDE_SHARE_REPO="test-owner/test-repo"
   export CLAUDE_SHARE_USERNAME="test-user"
   ```

## Making Changes

1. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Edit `scripts/share_session.py` for core functionality
   - Edit `commands/share.md` for command documentation
   - Update `README.md` if adding features or changing usage

3. **Test your changes**:
   - Reinstall the plugin: `/plugin uninstall share-sessions@claude-code-share-plugin`
   - Then: `/plugin install share-sessions@claude-code-share-plugin`
   - Test with: `/share test description`

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

## Commit Message Guidelines

Use conventional commits format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

## Pull Request Process

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a Pull Request with:
   - Clear description of changes
   - Why the change is needed
   - Any breaking changes
   - Screenshots/examples if applicable

3. Ensure your PR:
   - Follows the existing code style
   - Updates documentation as needed
   - Includes descriptive commit messages

## Testing

Before submitting a PR, test:
1. Plugin installation from local marketplace
2. Basic `/share` command without description
3. `/share` with description
4. Error handling (missing env vars, invalid repo, etc.)

## Code Style

- Python: Follow PEP 8 guidelines
- Use type hints where applicable
- Add docstrings to functions
- Keep functions focused and small
- Use meaningful variable names

## Areas for Contribution

- **Features**: New output formats, additional git hosting services
- **Bug fixes**: Issues with JSONL parsing, error handling
- **Documentation**: Improved examples, troubleshooting guides
- **Testing**: Better error messages, validation
- **Performance**: Optimize JSONL parsing, caching

## Questions?

Open an issue for:
- Bug reports
- Feature requests
- Questions about usage
- Clarifications on contributing

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
