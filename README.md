# Dotfiles Repository

## Overview

This repository provides a comprehensive shell configuration system with OpenCode AI integration for consistent development environments. It includes Bash configurations, Starship prompt, system tools, and OpenCode configs to enhance productivity across different systems.

## Quick Installation

Install the dotfiles on a new system:

```bash
curl -sSL https://raw.githubusercontent.com/one-ring-ai/dotfiles/main/setup.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/one-ring-ai/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

After installation, restart your shell or run `source ~/.bashrc` to apply changes.

## Setup Script Behavior

The setup script performs the following actions:

- Clones or updates the dotfiles repository to `~/dotfiles`
- Detects your package manager and installs required dependencies
- Installs MesloLGS Nerd Font for enhanced terminal display
- Sets up Starship prompt, FZF fuzzy finder, and Zoxide smart navigation
- Creates symbolic links to configuration files
- Configures Fastfetch for system information display
- Copies OpenCode configuration to `~/.config/opencode/`
- Backs up existing configurations before overwriting

The script is idempotent and safe to run multiple times.

## Configuration Layout

### `.config/opencode/`

Contains OpenCode AI assistant configuration and extensions:

- `agent/` - AI agent definitions for various development tasks
- `command/` - Custom command definitions
- `plugin/` - JavaScript plugins for OpenCode functionality
- `opencode.jsonc` - Main OpenCode configuration file
- `AGENTS.md` - Documentation for available agents

### `.config/fastfetch/`

- `config.jsonc` - Fastfetch system information tool configuration with organized sections for hardware, software, and system details

## OpenCode Integration

OpenCode is an AI-powered coding assistant integrated into the shell environment.

- Pre-configured agents for different development tasks (JavaScript, Python, Docker, etc.)
- Plugin system for extending functionality
- Custom commands for common operations
- Secure environment with permission controls

Start OpenCode with `opencode` and explore available agents in `.config/opencode/agent/`.

## Bash Configuration & Aliases

The `.bashrc` provides extensive shell enhancements:

- 200+ productivity aliases for file operations, system administration, and development workflows
- Enhanced navigation with directory shortcuts and auto-ls on directory change
- Git shortcuts and functions for common repository operations
- Safety features using trash-cli instead of permanent deletion
- Color-coded outputs and improved command history management
- Integration with development tools and package managers

Key aliases include file listing variants, archive extraction, network utilities, and system monitoring commands.

## Quickstart Guide Access

Access the terminal quickstart guide anytime using the `guide` alias:

```bash
guide
```

This opens `quickstart_guide.md` in your pager, providing essential commands and shortcuts for:

- OpenCode basics and plugin usage
- tmux terminal multiplexing
- Zoxide smart directory navigation
- FZF fuzzy finding
- Fastfetch system information
- Git workflows and text processing

The guide is copied to your home directory during setup for offline access.

## Testing & Validation

Validate the installation and configurations:

- Test OpenCode plugins: `bash docs/scripts/test-plugins.sh`
- Check Bash syntax: `bash -n ~/.bashrc`
- Verify OpenCode: `opencode --print-logs --log-level DEBUG .`
- Test setup in isolation: Run `./setup.sh` in a temporary directory

## Contributing

This repository follows conventional commit standards and uses semantic-release for automated versioning. See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for detailed guidelines.

## Uninstallation

Remove all configurations and restore backups:

```bash
cd ~/dotfiles
./uninstall.sh
```

This will:

- Remove symbolic links to configuration files
- Restore backed-up original configurations
- Uninstall optional dependencies
- Clean up font installations
- Remove the dotfiles directory

## Acknowledgments

This dotfiles configuration is based on the excellent work by [Chris Titus](https://github.com/ChrisTitusTech) from his [mybash repository](https://github.com/ChrisTitusTech/mybash). We've adapted and extended his configurations for OpenCode integration while maintaining the core functionality and philosophy of his original work.

Special thanks to Chris for creating such a comprehensive and well-documented shell configuration that has served as the foundation for this project.