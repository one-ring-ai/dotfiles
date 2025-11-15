---
status: draft
created_at: 2025-11-14T00:00:00Z
requester: user
context_links: []
related_ticket: null
related_research: []
related_operation: null
---

# Terminal Quickstart Guide Alias Implementation Plan

## Overview

Create a static quickstart guide within the repository and expose it via a `guide` alias so any VM provisioned from these dotfiles can display up-to-date instructions for tools like OpenCode and tmux directly from the terminal.

## Current State Analysis

The existing `.bashrc` defines `alias hlp='less ~/.bashrc_help'` (`.bashrc:129`), but no corresponding help file is delivered during setup and the alias name is not intuitive. `setup.sh` already symlinks `.bashrc` into the user home but does not propagate any quickstart documentation. No other terminal-based guide tooling exists in the repo.

## Desired End State

Each VM setup installs the repository’s `quickstart_guide.md` into the user’s home directory, `.bashrc` exposes an intuitive `guide` alias that opens the document with `less`, and the guide content lives in version control at the repository root. Running `guide` after setup should immediately show tool usage instructions without additional configuration.

### Key Discoveries
- `.bashrc` currently points to a missing `~/.bashrc_help` file (`.bashrc:129`).
- `setup.sh` (`setup_bash_config` function) links `.bashrc` but performs no extra file copies.
- No quickstart or wiki-style document is shipped today.

## What We're NOT Doing

- No interactive menu or dynamic content generation.
- No multi-language or localization support.
- No automation to ingest documentation from other files.

## Implementation Approach

Author a Markdown quickstart document at the repo root, copy it into the user’s home during setup alongside `.bashrc`, and rename the alias to `guide` referencing the new file. This keeps the workflow simple and ensures every VM provisioned with these dotfiles has the latest guide.

## Phase 1: Author Repository Quickstart Document

### Overview
Establish the canonical `quickstart_guide.md` at the repository root with clear sections for key tools.

### Changes Required

#### 1. Quickstart Content
**File**: `quickstart_guide.md`
**Changes**: Create a Markdown document outlining setup instructions, usage tips, and key commands for tools (e.g., OpenCode, tmux). Include headings (`#`, `##`) for navigability and a brief table of contents if desired. Keep formatting plain so it renders nicely in `less`.

### Success Criteria

#### Automated Verification
- [ ] `markdownlint` (if available) passes: `npx markdownlint-cli2 quickstart_guide.md`

#### Manual Verification
- [ ] Document reads cleanly in `less quickstart_guide.md`
- [ ] Sections adequately cover OpenCode, tmux, and other priority tools

---

## Phase 2: Update Bash Alias

### Overview
Refactor `.bashrc` so the alias is named `guide` and targets the new Markdown file in the user home directory.

### Changes Required

#### 1. Alias Definition
**File**: `.bashrc`
**Changes**:
- Replace `alias hlp='less ~/.bashrc_help'` with `alias guide='less "$HOME/quickstart_guide.md"'` (or equivalent using `$HOME`).
- Confirm documentation elsewhere (if any) references the correct alias name.

### Success Criteria

#### Automated Verification
- [ ] Syntax check passes: `bash -n .bashrc`

#### Manual Verification
- [ ] After running `source ~/.bashrc`, typing `guide` opens the Markdown guide
- [ ] Alias name is discoverable via `alias guide`

---

## Phase 3: Ensure Setup Copies Guide

### Overview
Modify `setup.sh` to deploy `quickstart_guide.md` into the target user’s home during provisioning, mirroring the handling of `.bashrc`.

### Changes Required

#### 1. Setup Script Copy Logic
**File**: `setup.sh`
**Changes**:
- In `setup_bash_config` (or adjacent helper), copy or symlink `${DOTFILES_DIR}/quickstart_guide.md` to `${user_home}/quickstart_guide.md`.
- Backup any pre-existing `~/quickstart_guide.md` similar to `.bashrc` handling.
- Log success/failure consistently with existing patterns.

### Success Criteria

#### Automated Verification
- [ ] Syntax check passes: `bash -n setup.sh`

#### Manual Verification
- [ ] Running `./setup.sh` places `quickstart_guide.md` in the user home alongside `.bashrc`
- [ ] After setup, `guide` opens the copied file without errors
- [ ] Re-running setup respects backups and idempotency expectations

---

## Phase 4: Validation & Documentation Touchpoints

### Overview
Confirm overall behavior and update any high-level documentation if needed.

### Changes Required

#### 1. Repository Documentation (Optional)
**File**: `README.md` (or appropriate section)
**Changes**: Mention availability of the `guide` command for terminal quickstart.

### Success Criteria

#### Automated Verification
- [ ] `markdownlint` passes for updated docs (if modified)

#### Manual Verification
- [ ] README or other docs accurately describe how to use `guide`
- [ ] dotfiles maintainers are aware of the new document/source-of-truth

---

## Testing Strategy

### Unit Tests
- Not applicable (configuration change).

### Integration Tests
- Run full setup flow via `./setup.sh` on a clean VM/container.

### Manual Testing Steps
1. Run `./setup.sh` on a fresh environment.
2. Open a new shell or `source ~/.bashrc`.
3. Execute `guide` and verify the Markdown renders in `less` with correct content.
4. Search within `less` (e.g., `/tmux`) to confirm navigation usability.

## Performance Considerations

- Copying a single Markdown file has negligible impact.
- `less` performance is unaffected by small documentation files.

## Migration Notes

- Users with existing custom `~/.bashrc_help` files will no longer reference them; document the change if needed.
- Backup logic should preserve prior `quickstart_guide.md` copies during setup.

## References

- `.bashrc` alias definition (line 129 prior to change).
- `setup.sh` `setup_bash_config` function (lines 318–352) handling dotfile linking.
