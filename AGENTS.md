# AGENTS.md

## Project Overview

Dotfiles repository for shell configuration (Bash, Starship) with OpenCode integration. Contains shell scripts, JavaScript plugins, and GitHub workflows for personal development environment setup.

## Build/Lint/Test Commands

- Test plugins: `bash docs/scripts/test-plugins.sh`
- Validate bash scripts: `bash -n <script>` (syntax check)
- Run setup: `./setup.sh`
- Manual testing: `opencode --print-logs --log-level DEBUG .`

## Code Style Guidelines

**Bash**: Use `set -euo pipefail`, readonly variables, proper quoting
**JavaScript (plugins)**: ES modules, async/await, clear naming
**File organization**: Separate concerns, semantic structure
**Testing**: Manual validation via plugin test script

## Code Comment Standards

### Comment Policy

- **Never write comments in the codebase** - Code should be self-explanatory through clear naming and structure
- If a file is too complex to understand without comments, it should be simplified and split into multiple files
- Follow sensible semantic organization and file structure
- Use descriptive variable names, function names, and file names instead of comments

## Git Conventions

### Conventional Commits

Follow the **Conventional Commits specification** for all commit messages:

**Format**: `<type>[optional scope]: <description>`

### Commit Types
- `feat`: New feature for the user
- `fix`: Bug fix for the user
- `docs`: Documentation changes
- `style`: Code formatting, missing semi colons, etc (no production code change)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes affecting build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Examples
```
feat(auth): add OAuth2 login support
fix(api): resolve timeout issue in user endpoint
docs: update deployment instructions
refactor(database): extract connection pooling logic
perf(cache): implement Redis-based session storage
test(user): add integration tests for registration flow
```

### Commit Message Rules

- Use imperative mood ("add" not "adds" or "added")
- Don't capitalize first letter of description
- No period at the end of description
- Include issue number when applicable: `fix(api): resolve timeout (#123)`
- Keep description under 50 characters
- Use body for detailed explanations when needed
- **Never mention Claude Code in commit messages** - Keep commits focused on the actual changes made
- **After completing a todo list**: Always write a commit message in chat summarizing what was accomplished