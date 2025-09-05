# One Ring AI Dotfiles

## Overview

This repository provides a comprehensive shell configuration system designed for VPS template deployment via Terraform. It includes a complete `.bashrc` configuration, Starship prompt, system tools installation, and Claude Code integration to create consistent development environments across multiple servers.

## Table of Contents

- [Quick Installation](#quick-installation)
- [Terraform Integration](#terraform-integration)
- [Configuration Files](#configuration-files)
- [Key Features](#key-features)
- [VPS Template Usage](#vps-template-usage)
- [Development Tools](#development-tools)
- [Uninstallation](#uninstallation)

## Quick Installation

For manual installation on a single server:

```bash
curl -sSL https://raw.githubusercontent.com/one-ring-ai/dotfiles/main/setup.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/one-ring-ai/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script automatically:
- Clones/updates the repository to `~/dotfiles`
- Detects your package manager and installs dependencies
- Installs MesloLGS Nerd Font
- Sets up Starship prompt, FZF, and Zoxide
- Creates symbolic links to configuration files
- Configures Fastfetch for system information display

## Terraform Integration

This repository is designed for automated VPS provisioning. The setup script:

1. **Auto-clones**: Downloads the repository if not present
2. **Updates automatically**: Runs `git pull` on existing installations  
3. **User-agnostic**: Works for any user/environment
4. **Idempotent**: Safe to run multiple times
5. **Symbolic links**: Configuration updates propagate automatically

### Terraform Usage Example

```hcl
resource "null_resource" "setup_dotfiles" {
  provisioner "remote-exec" {
    inline = [
      "curl -sSL https://raw.githubusercontent.com/one-ring-ai/dotfiles/main/setup.sh | bash",
      "source ~/.bashrc"
    ]
  }
}
```

## Configuration Files

### `.bashrc`
- **200+ aliases** for enhanced productivity
- **Custom functions** for file operations, system info, git workflows
- **Enhanced navigation** with directory shortcuts and auto-ls on cd
- **Development tools** integration (Docker, Git, package managers)
- **Safety features** using trash-cli instead of rm
- **Color-coded outputs** for better readability

### `starship.toml`
- **Contextual prompt** showing git status, language versions, etc.
- **Fast performance** with minimal latency
- **Custom formatting** optimized for development workflows

### `config.jsonc`
- **Fastfetch configuration** for system information display
- **Organized sections** for hardware, software, and system details
- **Color-coded output** matching the overall theme

### `.claude/` Directory
- **Claude Code settings** for AI-assisted development
- **Permission configurations** for secure tool usage
- **Project-specific instructions** and conventions

## Key Features

### Shell Enhancements
- **Smart aliases** that adapt based on available tools
- **Conditional path exports** for user-specific tools
- **History management** with timestamps and deduplication
- **Auto-completion** improvements and case-insensitive matching

### Development Tools
- **Git shortcuts** with `gcom()` and `gpush()` functions
- **Docker cleanup** aliases for container management  
- **Archive extraction** with universal `extract()` function
- **Network utilities** for IP detection and port monitoring

### System Administration
- **Distribution detection** with automatic package manager selection
- **Service management** shortcuts for common operations
- **Log monitoring** with multitail integration
- **Resource monitoring** aliases and functions

### Safety Features
- **Interactive confirmations** for destructive operations
- **Trash-cli integration** instead of permanent deletion
- **Backup creation** before overwriting configurations
- **Permission validation** before system modifications

## VPS Template Usage

### Folder Structure
```
~/dotfiles/
├── .bashrc           # Main shell configuration
├── setup.sh          # Installation script
├── uninstall.sh      # Removal script
├── config.jsonc      # Fastfetch configuration
├── starship.toml     # Prompt configuration
├── .claude/          # Claude Code settings
│   ├── CLAUDE.md     # Development standards
│   └── settings.local.json # Tool permissions
└── .github/          # CI/CD configurations
```

### Environment Variables
- `DOTFILESDIR`: Points to `~/dotfiles` for script usage
- `XDG_*`: Standard directories for configuration files
- Development tool paths automatically detected and configured

### Update Mechanism
When Terraform re-runs the setup script:
1. Repository is updated via `git pull`
2. Symlinks automatically point to updated files
3. No manual intervention required
4. Changes take effect on next shell session

## Development Tools

### Claude Code Integration
- Pre-configured permissions for common operations
- Project-specific coding standards and conventions
- Docker and development tool access controls

### Git Workflow
- Conventional commit message format
- Automated backup of existing configurations
- Branch-aware prompt with status indicators

### Package Management
- Multi-distribution support (Ubuntu, Arch, Fedora, etc.)
- Automatic dependency installation
- AUR helper setup for Arch-based systems

## Uninstallation

To remove the configuration:

```bash
cd ~/dotfiles
./uninstall.sh
```

This will:
- Remove all symbolic links
- Restore backed-up configurations
- Uninstall optional dependencies
- Clean up font installations
- Remove the dotfiles directory

## Contributing

This repository follows conventional commit messages and includes automated dependency updates via Dependabot. All configurations are designed to be portable across different Unix-like systems.

For issues or improvements, please open an issue or pull request.

## Acknowledgments

This dotfiles configuration is based on the excellent work by [Chris Titus](https://github.com/ChrisTitusTech) from his [mybash repository](https://github.com/ChrisTitusTech/mybash). We've adapted and extended his configurations for VPS template deployment and Terraform integration while maintaining the core functionality and philosophy of his original work.

Special thanks to Chris for creating such a comprehensive and well-documented shell configuration that has served as the foundation for this project.