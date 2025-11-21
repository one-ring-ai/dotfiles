---
status: completed
created_at: 2025-11-21
requester: user
files_edited:
  - .config/opencode/agent/complex-problem-researcher.md
rationale: Introduce a high-cost escalation path for deep research blockers requiring third-party analysis.
supporting_docs:
  - .config/opencode/agent/complex-problem-researcher.md
  - AGENTS.md
  - .github/CONTRIBUTING.md
follow_up_actions: []
---

## Summary of Changes
- Coordinated creation of `complex-problem-researcher` subagent with high-cost model frontmatter and read-only permissions.
- Added sections covering purpose, capabilities, usage policy with cost warning, research workflow, structured output format, and explicit constraints.
- Reinforced repository standards by updating the constraints list to enumerate citation, read-only, and knowledge-gap requirements.

## Technical Reasoning
- A dedicated escalation agent ensures orchestrator consistency when cheaper specialists cannot unblock multi-domain issues, aligning with AGENTS.md guidance on specialization.
- Explicit workflow and output expectations standardize how insights are consumed, reducing ambiguity for primary agents.
- Read-only and citation requirements comply with CONTRIBUTING.md policies and protect repository integrity while enabling thorough research.

## Impact Assessment
- Provides a controlled, well-documented path for invoking an expensive reasoning model only when necessary.
- Establishes clear guardrails that limit overuse and maintain traceability of research-heavy investigations.
- Enhances overall support structure by spelling out deliverable formats and follow-up expectations for complex blockers.

## Validation Steps
- Reviewed `.config/opencode/agent/complex-problem-researcher.md` to ensure all required sections and constraints are present.
- Confirmed alignment with CONTRIBUTING.md naming conventions and AGENTS.md specialization guidelines.
- Verified that no non-thoughts files were edited outside documented scope.
