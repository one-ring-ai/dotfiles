---
status: draft
created_at: 2025-12-10T19:36:14Z
requester: user
context_links:
  - .config/opencode/opencode.jsonc
  - .devcontainer.json
  - thoughts/shared/operations/2025-11-11-playwright-mcp-integration.md
  - thoughts/shared/operations/2025-11-12-chrome-devtools-mcp-configuration.md
related_ticket: null
related_research: null
related_operation: null
---

# Trivy MCP Integration for OpenCode (Devcontainer)

## Overview
Integrate Aqua Trivy via its official MCP server into the shared OpenCode stack, running inside the devcontainer image (`ghcr.io/lucanori/coder-templates:latest`). Provide a dedicated security agent and reproducible installation (pinned Trivy + MCP plugin), enabling filesystem and container image scanning with online DB updates.

## Phase Completion Status
- [x] Phase 1: Install Trivy CLI and MCP Plugin (devcontainer)
- [x] Phase 2: Register Trivy MCP in OpenCode config
- [x] Phase 3: Add Dedicated Security Agent
- [x] Phase 4: Validation and Docs

## Current State Analysis
- OpenCode config (`.config/opencode/opencode.jsonc`) includes only Figma MCP (lines 24-31); prior MCP additions followed the Playwright/Chrome DevTools patterns.
- Devcontainer (`.devcontainer.json`) runs with Docker socket mounted; VS Code Trivy extension is present, but CLI/MCP installation not guaranteed.
- No existing security-focused agent or MCP for Trivy; no Aqua Platform usage required.

## Desired End State
- Trivy CLI installed at a pinned version inside the devcontainer; MCP plugin installed and runnable via `trivy mcp` over stdio.
- OpenCode config registers a `trivy` MCP entry enabled by default, mirroring existing MCP patterns.
- Dedicated security agent configured to invoke Trivy MCP for local filesystem and container image scans.
- Clear instructions for cache location, online DB update (internet allowed), and optional offline flags if connectivity is down.

### Key Discoveries
- MCP pattern already established in `.config/opencode/opencode.jsonc` (figma) and documented in operations files.
- Devcontainer has Docker socket, enabling `trivy image` scans for local images; no Aqua Platform secrets needed.

## What We're NOT Doing
- No Aqua Platform integration (no `AQUA_KEY/SECRET`).
- No changes for non-devcontainer environments.
- No CI/GitHub Actions integration in this iteration.

## Implementation Approach
Use the official Trivy MCP plugin for a first-class MCP tool, installed during environment setup. Add an OpenCode MCP entry and a dedicated security agent. Provide defaults for online DB updates, with optional flags documented for transient offline cases.

## Phase 1: Install Trivy CLI and MCP Plugin (devcontainer)

### Overview
Ensure deterministic installation of Trivy and its MCP plugin in the devcontainer image runtime.

### Changes Required
1) `setup.sh` (or devcontainer bootstrap docs)
- Add install step to fetch pinned Trivy release (tarball) for Linux amd64; place binary in a PATH dir (e.g., `/usr/local/bin/trivy`) with checksum verification.
- Run `trivy plugin install mcp` post-install to make MCP command available.
- Create cache dir (e.g., `${HOME}/.cache/trivy`) with appropriate perms.

2) Version pinning
- Declare a single source of truth variable (e.g., `TRIVY_VERSION=0.55.x`) in `setup.sh` to ease future bumps.

### Success Criteria
#### Automated
- `trivy --version` returns pinned version.
- `trivy mcp --help` exits 0.
#### Manual
- `trivy fs --cache-dir $HOME/.cache/trivy .` completes against repo root.
- `trivy image --cache-dir $HOME/.cache/trivy alpine:3.19` runs (downloads DB from internet).

## Phase 2: Register Trivy MCP in OpenCode config

### Overview
Expose the MCP server so agents can call Trivy tools.

### Changes Required
1) `.config/opencode/opencode.jsonc`
- Under `mcp`, add:
```jsonc
"trivy": {
  "type": "local",
  "command": ["trivy", "mcp"],
  "enabled": true,
  "environment": {
    "TRIVY_CACHE_DIR": "{env:TRIVY_CACHE_DIR|~/.cache/trivy}"
  }
}
```
- Document optional flags (not enabled by default): `--skip-db-update --offline-scan` if connectivity is down; `--cache-backend redis://...` if later needed.

### Success Criteria
#### Automated
- Config validates (JSONC parses) and OpenCode starts without MCP errors.
#### Manual
- From OpenCode, list tools and see `trivy` MCP available.
- Invoke a sample MCP call: ask “Scan the current directory for vulns” and receive results.

## Phase 3: Add Dedicated Security Agent

### Overview
Provide an agent pre-wired to use Trivy MCP with guidance prompts.

### Changes Required
1) New agent definition `.config/opencode/agent/security-specialist.md`
- Role: use Trivy MCP for filesystem and container image scans.
- Prompts/rules:
  - Prefer `trivy fs` for local workspace.
  - For images: pull/build image then `trivy image <ref>`.
  - Use cache dir env (`TRIVY_CACHE_DIR`) and allow DB updates from internet.
  - When offline detected, fall back to `--offline-scan --skip-db-update` and note stale DB risk.
  - Avoid Aqua Platform options.
- Tools: enable MCP trivy.

### Success Criteria
#### Manual
- Selecting the agent and asking for a scan triggers Trivy MCP and returns findings.
- Agent instructions mention cache behavior and offline fallback.

## Phase 4: Validation and Docs

### Overview
Ensure usability in the devcontainer and document runbooks.

### Changes Required
1) Smoke tests
- Start MCP: `trivy mcp` (in a terminal) to confirm it binds stdio without errors.
- From OpenCode, run a sample scan via MCP (fs and a small image like `alpine:3.19`).

2) Docs (brief)
- Add a short note in `thoughts/shared/operations` or project docs describing: install step, MCP config, cache dir, sample commands, offline flags.

### Success Criteria
#### Manual
- Smoke test commands succeed without additional setup beyond `setup.sh`.
- Users in the devcontainer can run scans without extra installs.

## Testing Strategy
- Functional: `trivy fs .` and `trivy image alpine:3.19` from devcontainer.
- MCP: issue an MCP request from OpenCode and verify vulnerability list returns.
- Offline fallback (optional): run `trivy fs --offline-scan --skip-db-update .` to confirm graceful behavior when network blocked.

## Performance Considerations
- Enable cache dir to avoid repeated DB downloads; acceptable in devcontainer.
- Image scans pull layers via Docker socket; ensure adequate disk space in devcontainer.

## Migration Notes
- None; additive feature. If needed, add a guard to skip MCP registration when `trivy` binary absent (not expected in devcontainer once setup updated).

## References
- Trivy MCP server: https://github.com/aquasecurity/trivy-mcp
- Trivy docs: https://trivy.dev/docs/latest/
- Cache config: https://trivy.dev/docs/latest/configuration/cache/
- Air-gap flags: https://trivy.dev/docs/v0.55/guide/advanced/air-gap/
- Existing MCP patterns: `.config/opencode/opencode.jsonc` (figma), operations files listed above.
