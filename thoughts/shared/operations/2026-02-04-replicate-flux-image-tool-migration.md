---
status: completed
created_at: 2026-02-04
files_edited:
  - .config/opencode/tools/replicate-flux-image.ts
  - .config/opencode/skills/replicate-flux-image/SKILL.md
  - .config/opencode/skills/replicate-flux-image/README.md
  - .config/opencode/skills/replicate-flux-image/scripts/generate_image.py
  - .config/opencode/skills/replicate-flux-image/.env.example
  - .config/opencode/skills/replicate-flux-image/.gitignore
  - .config/opencode/skills/replicate-flux-image/cityscape.webp
rationale: Replace Python skill with TypeScript OpenCode tool for Replicate
supporting_docs:
  - https://opencode.ai/docs/custom-tools/
---

# Replicate Flux image tool migration

## Summary of changes

- Added a TypeScript OpenCode tool at `.config/opencode/tools/replicate-flux-image.ts`
  that wraps Replicate's flux-2-max API with validated inputs and local image
  download.
- Removed the previous Python-based skill and its supporting files under
  `.config/opencode/skills/replicate-flux-image/`.

## Technical reasoning

- Aligns with the OpenCode custom tool pattern using `tool.schema` for argument
  validation, defaulting required parameters, and enforcing integer bounds where
  the API expects integers.
- Handles custom aspect ratios by requiring width and height, clamping to
  256–2048 and rounding to the nearest multiple of 32; ignores resolution when
  custom to match API expectations.
- Uses Bearer authentication from `REPLICATE_API_TOKEN`, polls prediction status
  with a 5-minute timeout, and saves the downloaded image inside the active repo
  at `replicate-output/replicate-flux-image.<ext>`.

## Impact assessment

- New tool is discoverable under `.config/opencode/tools/replicate-flux-image.ts`;
  the old skill entry no longer exists, so calls should use the new tool name.
- Requires `REPLICATE_API_TOKEN` to be available as configured in
  `opencode.jsonc`; no other configuration changes were introduced.
- Default outputs are WebP at quality 80 with safety tolerance 2; callers can
  override via tool arguments within validated ranges.

## Validation steps

- Markdownlint: `npx markdownlint-cli thoughts/shared/status/2026-02-04-replicate-flux-skill-status.md`
- Markdownlint: `npx markdownlint-cli thoughts/shared/operations/2026-02-04-replicate-flux-image-tool-migration.md`
- Manual review of `.config/opencode/tools/replicate-flux-image.ts` for schema
  defaults, custom aspect-ratio handling, and download path behavior.
- Functional execution not run (no Replicate token in session).
