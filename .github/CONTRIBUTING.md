# Contributing to Dotfiles Repository

Welcome to the dotfiles repository! This guide will help you contribute effectively to this personal development environment setup.

## 🎯 Project Overview

This repository contains shell configurations, OpenCode integration, and development environment setup scripts. It uses automated releases via semantic-release and enforces strict code quality standards.

## 🚀 Getting Started

### Prerequisites
- Git
- Bash shell
- Node.js (for OpenCode plugins)
- Basic understanding of shell scripting

### Setup Your Development Environment

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/dotfiles.git
   ```

3. **Test the setup locally**
   ```bash
   # Test the setup script (dry run first)
   ./setup.sh --help
   
   # Test plugins
   bash docs/scripts/test-plugins.sh
   ```

4. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📁 Folder Structure

Understanding the repository structure is crucial for effective contributions:

### Root Level
- `setup.sh` - Main installation script
- `uninstall.sh` - Cleanup script
- `.bashrc` - Bash configuration
- `starship.toml` - Starship prompt configuration
- `AGENTS.md` - Agent documentation

### `.config/opencode/`
OpenCode integration configuration and plugins:
- `agent/` - AI agent definitions (`.md` files)
- `command/` - Custom command definitions
- `plugin/` - JavaScript plugins for OpenCode
- `skills/` - Reusable skill definitions
- `opencode.jsonc` - Main OpenCode configuration

### `.config/fastfetch/`
- `config.jsonc` - Fastfetch system information tool configuration

### `.github/`
GitHub automation and configuration:
- `workflows/` - CI/CD workflows
- `dependabot.yml` - Automated dependency updates

### `docs/`
Documentation and testing:
- `scripts/` - Test scripts and utilities
- `*.md` - Technical documentation

## 📝 Code Style Guidelines

### Bash Scripts
```bash
#!/usr/bin/env bash
set -euo pipefail  # Always use these options

# Use readonly for constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function naming: snake_case
function install_dependencies() {
    local package="$1"
    # Proper quoting
    if command -v "$package" >/dev/null 2>&1; then
        echo "$package is already installed"
    fi
}
```

**Requirements:**
- Always use `set -euo pipefail`
- Use readonly variables for constants
- Quote all variables: `"$variable"` not `$variable`
- Use snake_case for function and variable names
- Functions must be declared before use

### JavaScript (OpenCode Plugins)
```javascript
// ES modules only
export default {
    name: 'plugin-name',
    description: 'Clear description',
    execute: async function(context) {
        try {
            // Async/await preferred
            const result = await someAsyncOperation();
            return result;
        } catch (error) {
            console.error(`Plugin error: ${error.message}`);
            throw error;
        }
    }
};
```

**Requirements:**
- ES modules syntax only
- Use async/await for asynchronous operations
- Clear, descriptive function and variable names
- Proper error handling with try/catch
- Export default object with name, description, execute

### 🚫 NO COMMENTS POLICY (CRITICAL)

**This repository has a strict no-comments policy.**

- **NEVER write comments in the codebase**
- Code should be self-explanatory through clear naming and structure
- If code is too complex without comments, simplify and split into multiple files
- Use descriptive variable names, function names, and file names
- Follow semantic organization and file structure

**Examples:**
```bash
# ❌ BAD - With comments
# Check if package is installed
if command -v "$package" >/dev/null 2>&1; then
    echo "$package found"  # Print success message
fi

# ✅ GOOD - Self-explanatory
is_package_installed() {
    local package="$1"
    command -v "$package" >/dev/null 2>&1
}

if is_package_installed "$package"; then
    echo "$package is available"
fi
```

### File Naming Conventions
- Scripts: `kebab-case.sh` (e.g., `setup-script.sh`)
- Config files: `kebab-case` or `camelCase` depending on tool requirements
- Documentation: `kebab-case.md`
- Plugins: `kebab-case.js`

## 🔄 Conventional Commits (REQUIRED)

**This repository uses semantic-release, which REQUIRES conventional commits.**

### Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types
- `feat`: New feature for the user
- `fix`: Bug fix for the user  
- `docs`: Documentation changes only
- `style`: Code formatting, no production code change
- `refactor`: Code change that neither fixes bug nor adds feature
- `perf`: Performance improvement
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Examples
```bash
feat(opencode): add new plugin system
fix(setup): resolve permission issues in installation
docs: update contributing guidelines
refactor(bash): extract common functions to utils
perf(startup): optimize shell initialization
test(plugins): add integration tests for plugin system
build: update dependencies to latest versions
ci: add automated testing workflow
chore: update README with new features
revert: undo previous plugin changes
```

### Commit Message Rules
- Use imperative mood ("add" not "adds" or "added")
- Don't capitalize first letter
- No period at the end
- Keep description under 50 characters
- Include scope when applicable: `feat(scope): description`
- Use body for detailed explanations when needed

### Impact on Releases
- `feat` commits trigger minor version bump
- `fix` commits trigger patch version bump  
- Commits with `BREAKING CHANGE:` footer trigger major version bump
- Other types don't trigger version bumps

## 🧪 Testing

### Testing OpenCode Plugins
```bash
# Run all plugin tests
bash docs/scripts/test-plugins.sh

# Test specific plugin
opencode --print-logs --log-level DEBUG .
```

### Validating Bash Scripts
```bash
# Syntax check
bash -n script-name.sh

# Shellcheck (if available)
shellcheck script-name.sh
```

### Testing Setup Process
```bash
# Test setup in temporary directory
mkdir /tmp/test-dotfiles
cd /tmp/test-dotfiles
git clone YOUR_FORK_URL .
./setup.sh
```

## 🔀 Pull Request Process

### Branching Strategy
- `main` - Production branch (protected)
- `beta` - Beta releases branch
- `alpha` - Alpha releases branch
- `feature/*` - Feature development branches
- `fix/*` - Bug fix branches

### PR Requirements
1. **Conventional commits** - All commits must follow conventional commit format
2. **Tests passing** - All tests must pass
3. **No comments** - Code must follow no-comments policy
4. **Code style** - Must follow style guidelines
5. **Documentation** - Update relevant documentation

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Plugin tests pass
- [ ] Bash scripts validate
- [ ] Setup script tested

## Checklist
- [ ] Conventional commits used
- [ ] No comments in code
- [ ] Code style guidelines followed
- [ ] Documentation updated
```

## 🚀 Release Process

### Automated Releases
This repository uses **semantic-release** for fully automated releases:

- **Commits to `main`** → Production releases
- **Commits to `beta`** → Beta releases  
- **Commits to `alpha`** → Alpha releases

### Release Triggers
- `feat` commits → Minor version (1.x.0)
- `fix` commits → Patch version (1.0.x)
- `BREAKING CHANGE:` → Major version (2.0.0)

### Branch Strategy
```
main (production) ← beta ← alpha ← feature branches
```

### What Happens Automatically
1. Analyzes commit messages since last release
2. Determines next version number
3. Generates changelog
4. Creates Git tag
5. Creates GitHub release
6. Updates version in files

## 🤝 Additional Guidelines

### Before Contributing
- Read existing code to understand patterns
- Check existing issues for similar work
- Start with good first issues if new to project

### Code Review Process
- All PRs require review
- Focus on code quality, style, and functionality
- Ensure conventional commits are properly formatted

### Getting Help
- Check existing documentation in `docs/`
- Review existing code patterns
- Ask questions in PR discussions

---

Thank you for contributing to this dotfiles repository! Your contributions help improve the development experience for everyone.