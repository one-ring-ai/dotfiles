---
status: open
created_at: 2025-11-09
requester: user
context_links:
   - .config/opencode/agent/github-actions-workflow-specialist.md
  - https://docs.github.com/en/actions/using-workflows/reusing-workflows
  - https://www.chainguard.dev/unchained/github-actions-security-cheat-sheet
  - https://www.sonarsource.com/blog/github-actions-security-best-practices
  - https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
---

## Problem Statement
The current `cicd-devops-specialist` agent covers broad CI/CD, infrastructure automation, and cloud-native topics. The user requested narrowing its scope to a GitHub Actions workflow specialist focused on authoring, securing, and optimizing GitHub workflows.

## Research Summary
- GitHub reusable workflows should be defined with `on: workflow_call`, explicit inputs/secrets, and called with commit-SHA pinning for security ([GitHub Docs](https://docs.github.com/en/actions/using-workflows/reusing-workflows)).
- GitHub Actions security guidance emphasizes minimal `GITHUB_TOKEN` permissions, OIDC-based cloud auth, and pinning third-party actions to SHAs ([Chainguard](https://www.chainguard.dev/unchained/github-actions-security-cheat-sheet); [SonarSource](https://www.sonarsource.com/blog/github-actions-security-best-practices)).
- Workflow syntax best practices include structured triggers, job dependencies via `needs`, `concurrency` groups for canceling redundant runs, and `defaults` for consistent shells/paths ([GitHub Docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)).
- Effective workflows use caching keyed by dependency manifests, matrix strategies for multiple environments, and artifact management to share build outputs ([GitHub Docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)).

## Requirements
1. Update the agent description to a GitHub Actions workflow specialist and remove non-GitHub CI/CD platform content (e.g., Terraform, Kubernetes, AWS CodePipeline, Azure DevOps).
2. Rewrite core sections to cover:
   - Workflow structure (triggers, jobs, concurrency, environments, reusable workflows)
   - Security and compliance (permissions, secrets, OIDC, review policies)
   - Efficiency (caching, matrix builds, conditional execution, artifact reuse)
   - Testing and quality gates (linting, coverage, security scans via marketplace actions)
   - Deployment patterns within GitHub Actions (environment protections, approvals, integrations with cloud providers via official actions)
   - Observability and maintainability (logs, annotations, dependency updates, documentation expectations)
3. Provide updated YAML snippets illustrating best practices for GitHub Actions (e.g., minimal permissions, concurrency, matrix execution, reusable workflow invocation).
4. Align instructions with repository policies (read CONTRIBUTING.md, AGENTS.md) and emphasize no comments rule where relevant.

## Acceptance Criteria
- Agent file focuses exclusively on GitHub Actions workflows and related tooling.
- All references to non-GitHub CI/CD platforms and unrelated infrastructure are removed.
- New content reflects 2024-2025 GitHub Actions best practices, including security hardening and workflow optimization strategies.
- Structure remains clear, actionable, and compliant with repository documentation standards.
- Ticket remains open until implementation is validated and corresponding operation record is created.
