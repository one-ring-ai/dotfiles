---
status: completed
created_at: 2026-02-25
files_edited:
  - .config/opencode/agent/documentation-writer.md
rationale:
  - Add an explicit pre-lint guardrail so documentation workflows verify markdownlint config presence and canonical alignment before lint execution
supporting_docs:
  - https://raw.githubusercontent.com/one-ring-ai/dotfiles/refs/heads/main/.markdownlint.json
  - https://raw.githubusercontent.com/one-ring-ai/dotfiles/refs/heads/main/.markdownlintignore
---

## Summary of changes

Added a new **Lint Config Guardrail** rule in `.config/opencode/agent/documentation-writer.md`.
The rule requires checking that `.markdownlint.json` and `.markdownlintignore` exist at repository root and match the canonical upstream files before running `markdownlint-cli`.

## Technical reasoning

Running markdown lint with missing or divergent config files can produce inconsistent results across environments.
Making this check explicit in the documentation-writer agent reduces drift and keeps lint behavior predictable.

## Impact assessment

- Improves consistency of markdown linting outcomes.
- Reduces accidental configuration drift for markdown lint rules.
- Adds no runtime or behavior changes outside documentation workflow guidance.

## Validation steps

1. Updated the target agent file.
2. Ran:

   `npx markdownlint-cli "**/*.md" --config .markdownlint.json --ignore-path .markdownlintignore --dot --fix`

3. Confirmed only the intended documentation file changed for the requested feature.
