---
status: completed
created_at: 2026-02-08
files_edited:
  - .config/opencode/setup.sh
  - .config/opencode/sync-opencode-scheduled.sh
  - docs/scripts/build-setup-assets.sh
  - .releaserc.json
  - .github/workflows/release.yml
  - .gitignore
  - README.md
  - docs/release-assets-and-scheduler.md
rationale: Enable release checksum assets and scheduled verified sync for OpenCode configs
supporting_docs:
  - thoughts/shared/plans/2026-02-08-release-checksum-assets.md
  - thoughts/shared/plans/2026-02-08-sync-opencode-cron.md
  - https://github.com/cycjimmy/semantic-release-action
---

# Operation: release assets and scheduler

## Summary of changes

- Added build script that copies `.config/opencode/setup.sh` into
  `artifacts/` and produces a sha256 checksum for release assets.
- Extended semantic-release to run the build script in `prepare`, attach setup
  and checksum as GitHub release assets, ignore `artifacts/` in git, and update
  the workflow to install `@semantic-release/exec`.
- Introduced a scheduled sync wrapper that downloads release assets with
  checksum verification, handles cron/launchd install/remove/status, and added
  schedule flags to `setup.sh` while preserving the default sync flow.
- Switched the scheduled sync downloads to a persistent state directory
  (`~/.local/state/sync-opencode/downloads`) instead of ephemeral temp folders
  to avoid removal during cron execution, keeping checksum verification and the
  existing locking/logging behavior unchanged.

## Technical reasoning

- Release assets are generated before publish via `@semantic-release/exec`,
  ensuring `setup.sh` and its checksum match the release tag; assets are listed
  for GitHub uploads and excluded from version control to avoid local noise.
- The scheduler wrapper enforces deterministic PATH, locking (flock or
  pidfile), 1MB log rotation, and channel selection via the GitHub Releases
  API, with checksum verification using sha256sum or shasum; execution uses
  timeout when available.
- `setup.sh` now parses schedule flags, runs the standard sync to place the
  wrapper, and delegates scheduling so user-level cron/launchd entries call the
  verified wrapper with the chosen channel and interval.
- Persistent download location prevents cron from losing the fetched `setup.sh`
  while still cleaning/replacing the pair of download files per run.

## Impact assessment

- Releases will now ship `setup.sh` and `setup.sh.sha256` assets; failures in
  checksum generation or missing assets will stop the release job.
- Local artifacts remain untracked; release workflow installs the exec plugin
  explicitly to match the config.
- Users can opt into scheduled sync on Linux or macOS without root; runs use
  release assets with checksum verification and skip overlapping executions.

## Validation steps

- bash -n .config/opencode/setup.sh
- bash -n .config/opencode/sync-opencode-scheduled.sh
- bash -n docs/scripts/build-setup-assets.sh
