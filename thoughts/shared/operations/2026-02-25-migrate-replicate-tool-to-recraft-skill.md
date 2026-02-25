---
status: completed
created_at: 2026-02-25
files_edited:
  - .config/opencode/tools/replicate-flux-image.ts
  - .config/opencode/skills/replicate-recraft-svg/SKILL.md
  - .config/opencode/agent/frontend-html-css-specialist.md
  - .config/opencode/agent/web-app-dev.md
  - .config/opencode/agent/static-site-dev.md
  - thoughts/shared/status/2026-02-25-recraft-skill-migration-preexisting.md
rationale:
  - Replace the old Flux tool implementation with a skill-first workflow that calls Replicate directly from Bash
  - Switch image generation guidance to the SVG-focused model recraft-ai/recraft-v4-svg for web-friendly assets
supporting_docs:
  - https://replicate.com/recraft-ai/recraft-v4-svg/api/api-reference
  - https://replicate.com/docs/reference/http
  - https://opencode.ai/docs/skills/
---

## Summary of changes

- Removed the TypeScript tool `.config/opencode/tools/replicate-flux-image.ts`.
- Added new skill `.config/opencode/skills/replicate-recraft-svg/SKILL.md`.
- The new skill documents a direct Bash HTTP flow against `recraft-ai/recraft-v4-svg` using `curl` and `Prefer: wait`.
- Updated agent guidance in frontend/static/web-app specialist files to use the new `replicate-recraft-svg` skill instead of the removed tool.
- Recorded baseline unrelated workspace changes in `thoughts/shared/status/2026-02-25-recraft-skill-migration-preexisting.md`.

## Technical reasoning

The requested migration removes a custom runtime tool and centralizes usage in a skill, making invocation simpler and transparent.
Using `recraft-ai/recraft-v4-svg` aligns with the requested SVG output and web delivery needs.
The skill enforces the provided schema behavior:

- `prompt` required
- optional `aspect_ratio` and `size`
- `size` omitted when `aspect_ratio` is set to a value other than `Not set`

The Bash workflow retrieves the token from `~/.config/opencode/.secrets/replicate-key`, sends a direct API call, extracts output URI, and downloads the resulting `.svg`.

## Impact assessment

- Positive: simpler and explicit image generation flow via skill instructions.
- Positive: SVG-first output improves integration for website assets.
- Breaking change: workflows that invoked `replicate-flux-image` tool directly will no longer work until updated to skill usage.
- Low risk: provider settings in `.config/opencode/opencode.jsonc` remain unchanged and already support Replicate token handling.

## Validation steps

1. Confirmed pre-existing unrelated changes and documented them under `thoughts/shared/status/`.
2. Verified all direct references to `replicate-flux-image` in active agent definitions were migrated.
3. Ran markdown lint autofix:

   `npx markdownlint-cli "**/*.md" --config .markdownlint.json --ignore-path .markdownlintignore --dot --fix`

4. Inspected `git status` and `git diff` to ensure intended file scope only.
