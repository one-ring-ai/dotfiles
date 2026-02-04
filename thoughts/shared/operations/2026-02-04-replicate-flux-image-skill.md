---
status: completed
created_at: 2026-02-04
files_edited:
  - .config/opencode/skills/replicate-flux-image/SKILL.md
  - .config/opencode/skills/replicate-flux-image/README.md
  - .config/opencode/skills/replicate-flux-image/.env.example
  - .config/opencode/skills/replicate-flux-image/.gitignore
  - .config/opencode/skills/replicate-flux-image/scripts/generate_image.py
  - .config/opencode/opencode.jsonc
  - thoughts/shared/status/2026-02-04-initial.md
  - .gitignore
  - README.md
rationale: Added Replicate flux image skill with fixed parameters and configured secret handling
supporting_docs:
  - thoughts/shared/plans/2026-02-04-imagen-like-opencode-skill.md
  - https://replicate.com/black-forest-labs/flux-2-max
---

# Replicate flux image skill

## Summary of changes

- Added the `replicate-flux-image` skill with SKILL metadata, README usage, env
  template, and gitignore for generated images.
- Implemented the Python CLI to call Replicate flux-2-max with fixed
  parameters, improved output handling (string or list), timeout, and auth via
  `REPLICATE_API_TOKEN`.
- Configured OpenCode to source the Replicate token from
  `~/.config/opencode/.secrets/replicate-key`.
- Recorded status updates and ensured markdown files comply with lint rules.

## Technical reasoning

- Fixed model inputs to match plan: resolution 4 MP, webp, quality 100, safety
  tolerance 5; exposed only prompt and aspect_ratio enum to users for
  predictable behavior.
- Switched auth header to Bearer and added prompt validation; used
  `time.monotonic()` for reliable timeout tracking.
- Handled Replicate outputs that may return a single URL string or a list,
  avoiding false “No image URL” errors.
- Added secrets reference in `opencode.jsonc` to align with existing secret
  file pattern used for OpenRouter.

## Impact assessment

- Skill enables reproducible image generation via Replicate directly from
  OpenCode workflows.
- Token management is centralized in the OpenCode secrets path, reducing risk of
  accidental exposure.
- Generated assets remain out of git via dedicated skill-level gitignore entry.

## Validation steps

- `npx markdownlint-cli .config/opencode/skills/replicate-flux-image/SKILL.md
  .config/opencode/skills/replicate-flux-image/README.md
  thoughts/shared/status/2026-02-04-initial.md`
- Manual run reported by user succeeded after output handling fix (Replicate
  returned direct URL; download now handled).
