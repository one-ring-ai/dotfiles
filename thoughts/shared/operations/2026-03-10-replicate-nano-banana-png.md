---
status: completed
created_at: 2026-03-10
files_edited:
  - .config/opencode/skills/replicate-nano-banana-png/SKILL.md
  - thoughts/shared/status/2026-03-10-nano-banana-png-skill.md
rationale: Added a Replicate nano-banana-2 PNG generation skill with default PNG/1K settings and recorded the working tree change.
  - https://replicate.com/google/nano-banana-2
  - https://replicate.com/google/nano-banana-2/versions/71516450bdbeafc41df33ad538bc8cc6a90f80038a563b1260531c02d694f4fd/api
  - https://replicate.com/docs/reference/http
---

## Summary of changes

- Added `replicate-nano-banana-png` skill markdown covering Replicate `google/nano-banana-2` PNG generation with the provided input/output schema, defaulting to `resolution=1K` and `output_format=png`.
- Logged the presence of the new skill directory in `thoughts/shared/status/2026-03-10-nano-banana-png-skill.md` for change tracking.

## Technical reasoning

- Chose naming consistent with existing Replicate skill pattern (`replicate-<model>-<format>`), targeting PNG output.
- Used model version `71516450bdbeafc41df33ad538bc8cc6a90f80038a563b1260531c02d694f4fd` and Replicate HTTP POST `/v1/predictions` with `Prefer: wait` to return a single URL.
- Defaulted inputs per request: `resolution=1K`, `output_format=png`, `aspect_ratio=match_input_image`, with optional `google_search`/`image_search` grounding flags and `image_input` list.

## Impact assessment

- Scope limited to documentation/skill addition; no runtime scripts or config altered beyond lint config sync.
- No risk to existing setup; new skill is additive and optional.

## Validation steps

- Reviewed the generated skill file for schema accuracy and bash workflow correctness.
- Synced markdownlint config and ran `npx markdownlint-cli "**/*.md" --config .markdownlint.json --ignore-path .markdownlintignore --dot --fix` with no reported issues.
