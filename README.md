# Dotfiles Repository

## Overview

Shell configuration with OpenCode integration, Bash and Starship setup, and
supporting scripts for consistent developer environments.

## Quick installation

Install on a new system:

```bash
curl -sSL https://raw.githubusercontent.com/one-ring-ai/dotfiles/main/setup.sh \
  | bash
```

Or clone and run locally:

```bash
git clone https://github.com/one-ring-ai/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

After installation, restart your shell or run `source ~/.bashrc`.

## Release assets and scheduled sync

See [release-assets-and-scheduler](docs/release-assets-and-scheduler.md) for
using signed release artifacts and enabling the optional scheduled sync on
Linux (cron) and macOS (launchd).

## Setup script behavior

The setup script:

- Clones or updates the dotfiles repository to `~/dotfiles`
- Detects the package manager and installs required dependencies
- Installs MesloLGS Nerd Font
- Sets up Starship, FZF, and Zoxide
- Copies OpenCode configuration to `~/.config/opencode/`
- Backs up existing configurations before overwriting

The script is idempotent and safe to run multiple times.

## Configuration layout

### `.config/opencode/`

- `agent/` – AI agent definitions
- `command/` – Custom command definitions
- `plugin/` – OpenCode plugins
- `opencode.jsonc` – Main OpenCode configuration
- `AGENTS.md` – Agent documentation

### `.config/fastfetch/`

- `config.jsonc` – Fastfetch system information configuration

## OpenCode integration

OpenCode is preconfigured with agents, plugins, commands, and permissions.
Start it with `opencode` and browse agents in `.config/opencode/agent/`.

## Bash configuration and aliases

The `.bashrc` includes navigation helpers, safety defaults, Git shortcuts, and
many aliases for system and development workflows. The `guide` alias opens the
quickstart in `quickstart_guide.md`.

## Testing and validation

- Test OpenCode plugins: `bash docs/scripts/test-plugins.sh`
- Check Bash syntax: `bash -n ~/.bashrc`
- Verify OpenCode: `opencode --print-logs --log-level DEBUG .`
- Test setup in isolation: run `./setup.sh` in a temporary directory

## Contributing

Uses conventional commits and semantic-release. See
[CONTRIBUTING.md](.github/CONTRIBUTING.md).

## Uninstallation

```bash
cd ~/dotfiles
./uninstall.sh
```

The script removes symlinks, restores backups, uninstalls optional dependencies,
cleans font installs, and removes the dotfiles directory.

## Acknowledgments

Based on [ChrisTitusTech/mybash](https://github.com/ChrisTitusTech/mybash), with
extensions for OpenCode integration.
