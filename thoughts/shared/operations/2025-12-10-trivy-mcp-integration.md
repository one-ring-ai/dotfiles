---
status: completed
created_at: 2025-12-10
requester: user
files_edited: [.config/opencode/opencode.jsonc, .config/opencode/agent/security-specialist.md, setup.sh]
rationale: Add Trivy MCP tooling to devcontainer and OpenCode stack for security scanning
supporting_docs: [thoughts/shared/plans/2025-12-10-trivy-mcp-opencode.md, https://github.com/aquasecurity/trivy-mcp, https://trivy.dev/docs/latest/]
follow_up_actions: []
---

# Summary of Changes

Integrated Trivy MCP (Model Context Protocol) tooling into the OpenCode development environment stack. Added security-specialist agent configuration, updated OpenCode configuration to include Trivy MCP server, and modified setup script to install Trivy and configure MCP integration.

# Technical Reasoning

Trivy MCP provides AI-native security scanning capabilities that integrate with language models through the Model Context Protocol. This enables security-specialist agent to perform contextual security analysis, vulnerability scanning, and remediation guidance directly within the OpenCode workflow. The integration supports both filesystem and container image scanning with offline capabilities.

# Impact Assessment

## Security Posture

- Enhanced vulnerability detection across codebase and container images
- AI-driven security analysis integrated into development workflow
- Automated security scanning during development process

## Development Workflow

- Security-specialist agent gains access to comprehensive security tooling
- Seamless integration with existing OpenCode agent ecosystem
- Minimal overhead with configurable caching and offline modes

## System Resources

- Trivy cache directory: `$HOME/.cache/trivy`
- MCP server runs as background process
- Configurable resource usage through Trivy configuration

# Validation Steps

## Installation Verification

```bash
# Verify Trivy installation
trivy --version

# Verify MCP server availability
trivy mcp --help

# Test filesystem scanning
TRIVY_CACHE_DIR="$HOME/.cache/trivy" trivy fs .

# Test image scanning
TRIVY_CACHE_DIR="$HOME/.cache/trivy" trivy image alpine:3.19
```

## OpenCode Integration Test

```bash
# Test security-specialist agent access
opencode --print-logs --log-level DEBUG .
```

# Usage Notes

## Cache Configuration

- Default cache directory: `$HOME/.cache/trivy`
- Set `TRIVY_CACHE_DIR` environment variable to customize location
- Cache persists between scans for improved performance

## Sample Commands

```bash
# Filesystem scan with custom cache
TRIVY_CACHE_DIR="$HOME/.cache/trivy" trivy fs .

# Container image scanning
TRIVY_CACHE_DIR="$HOME/.cache/trivy" trivy image alpine:3.19

# MCP server smoke test
trivy mcp --help
```

## Offline Operation

When network connectivity is limited, use offline flags:

```bash
trivy fs . --offline-scan --skip-db-update
trivy image alpine:3.19 --offline-scan --skip-db-update
```

## MCP Usage Expectation

The security-specialist agent can now:

- Perform contextual vulnerability analysis
- Generate security remediation recommendations
- Scan both source code and container images
- Provide AI-driven security insights through MCP protocol

## Configuration Notes

- MCP server automatically configured in OpenCode stack
- Security-specialist agent includes Trivy-specific capabilities
- Setup script handles installation and initial configuration
- Supports both online and offline scanning modes
