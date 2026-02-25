---
status: completed
created_at: 2025-11-11
requester: user
files_edited:
  - .config/opencode/opencode.jsonc
rationale: Add Playwright MCP server to enable browser automation and responsive testing actions for OpenCode agents.
supporting_docs:
  - https://github.com/microsoft/playwright-mcp
follow_up_actions: []
---

## Summary of Changes

- Added a Playwright MCP server entry to `.config/opencode/opencode.jsonc` alongside the existing Figma configuration.
- Configured the server to run locally via `npx -y @microsoft/playwright-mcp --stdio`, enabling browser-driven interactions for agents.

## Technical Reasoning

- Playwright MCP provides cross-browser automation with tooling for viewport management, interactive actions, and responsive validation, aligning with the requested capabilities.
- The local server setup matches existing MCP patterns in the repository, maintaining consistent configuration structure.

## Impact Assessment

- OpenCode agents can now invoke Playwright to perform browser automation tasks, including interaction tests across multiple device profiles.
- Requires Node.js availability and network access for `npx` package retrieval when the server starts.

## Validation Steps

- Reviewed `.config/opencode/opencode.jsonc` to ensure only the Playwright entry was introduced and formatting remained consistent.
- Checked `git diff` and `git status` to confirm no unintended changes were introduced.
