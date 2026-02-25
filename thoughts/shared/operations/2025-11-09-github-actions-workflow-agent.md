---
status: completed
created_at: 2025-11-09
requester: user
files_edited:
  - .config/opencode/agent/github-actions-workflow-specialist.md
  - .config/opencode/agent/3-orchestrator.md
rationale: Update GitHub workflow specialist agent and orchestrator instructions per user request.
supporting_docs:
  - thoughts/shared/tickets/2025-11-09-github-actions-workflow-agent.md
follow_up_actions: []
---

## Summary of Changes

- Transformed the `cicd-devops-specialist` agent into a GitHub Actions workflow specialist, updating its description and guidance to focus solely on GitHub workflows.
- Replaced broad CI/CD content (Terraform, Kubernetes, external pipelines) with GitHub-specific best practices covering structure, security, efficiency, testing, deployment, and maintainability.
- Added current YAML examples illustrating minimal permissions, reusable workflows, caching, matrix execution, concurrency, and secure cloud integrations.
- Clarified orchestrator ticket policy: tickets are opened only on explicit user instruction; otherwise document outcomes via operation records. Reinforced obligation to complete assigned plans/tasks without pausing except for user clarification or required manual intervention.

## Technical Reasoning

- GitHub Actions specialization aligns the agent with repository needs and user direction. Security guidance emphasizes minimal permissions, OIDC, and pinned SHAs based on 2024+ best practices from GitHub Docs, Chainguard, and SonarSource.
- Workflow efficiency improvements leverage concurrency control, caching strategies, and conditional jobs to reduce runtime and cost. YAML snippets demonstrate these patterns.
- Updated orchestrator instructions reduce unnecessary ticket creation and ensure uninterrupted execution when plans/tasks are assigned, matching user expectations.

## Impact Assessment

- Provides a focused, authoritative reference for automating CI/CD pipelines via GitHub Actions within the repository. Removes outdated or irrelevant platform guidance, reducing cognitive load for contributors.
- Ensures future workflows prioritize security and maintainability, aligning with project policies and industry recommendations.
- Sets clearer orchestration boundaries, improving coordination discipline and documentation consistency.

## Validation Steps

- Reviewed rewritten agent files to confirm scope shift and adherence to repository guidelines (CONTRIBUTING.md, AGENTS.md).
- Verified ticket requirements were satisfied and recorded this operation for traceability.
