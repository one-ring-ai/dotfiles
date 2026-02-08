# Release assets and scheduled sync

## Release assets

- Each release publishes `setup.sh` and `setup.sh.sha256` as assets.
- Channels: stable = latest non-prerelease; beta/alpha = latest prerelease whose
  tag or name matches.
- Always prefer tagged releases instead of `main` when running unattended.

### Download and verify

```bash
TAG=<release-tag>
BASE="https://github.com/one-ring-ai/dotfiles/releases/download/${TAG}"
curl -fL -o setup.sh "${BASE}/setup.sh"
curl -fL -o setup.sh.sha256 "${BASE}/setup.sh.sha256"
sha256sum --check setup.sh.sha256  # macOS: shasum -a 256 --check setup.sh.sha256
bash setup.sh
```

## Scheduled sync wrapper

Script: `~/.config/opencode/sync-opencode-scheduled.sh`

- Channels: `stable` (default), `beta`, `alpha`.
- Single-run flow: download release assets for the channel, verify checksum, run
  setup with a 300s timeout when `timeout`/`gtimeout` is available.
- Prerequisites: `curl`, `bash`, `python3` or `python`, checksum tool
  (`sha256sum` or `shasum -a 256`), optional `timeout`/`gtimeout` for time-bound
  execution.
- Logging: `~/.local/state/sync-opencode/{sync.log,cron.log,stdout.log,stderr.log}`
  with 1MB rotation.
- Locking: uses `flock` when present, otherwise a pidfile; skips if another run
  is active.
- The `sync-opencode` alias in shell rc still pulls `main`; the scheduled wrapper
  always uses release assets and checksum verification.

### Run once manually

```bash
~/.config/opencode/sync-opencode-scheduled.sh --channel stable
```

### Install scheduler (Linux cron)

- Default interval: `0 */4 * * *` (every 4 hours).
- Install:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-install --channel stable
```

- Custom interval examples:
  - Seconds: `--interval 7200` (every 2h, converted to cron)
  - Cron spec: `--interval "15 * * * *"`
- Remove:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-remove
```

- Status:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-status
```

### Install scheduler (macOS launchd)

- Default interval: `StartInterval` 14400 seconds (4 hours).
- Install:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-install --channel stable
```

- Custom interval (seconds):

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-install \
  --channel beta --interval 10800
```

- Remove:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-remove
```

- Status:

```bash
~/.config/opencode/sync-opencode-scheduled.sh --schedule-status
```

## Logs and cache

- Logs: `~/.local/state/sync-opencode/{sync.log,cron.log,stdout.log,stderr.log}`
- Quick view:

```bash
tail -n 50 ~/.local/state/sync-opencode/{sync.log,stderr.log}
```

- Downloads: each run stores assets in a per-run folder under
  `~/.local/state/sync-opencode/downloads/run.*`. They are not auto-removed;
  you can clear old runs when no sync is active:

```bash
rm -rf ~/.local/state/sync-opencode/downloads/run.*
```

## Safety notes

- Checksums must pass before execution; empty downloads fail fast.
- Runs skip when a lock is held.
- Execution timeout is 300s when `timeout`/`gtimeout` is available.
