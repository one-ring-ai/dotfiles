# Plan: schedule `sync-opencode` on Linux (cron) and macOS (launchd)

## Goal

Add an optional, user-level scheduled execution of `sync-opencode` so the
OpenCode configs stay up to date automatically on both Linux and macOS, without
breaking existing behavior. No code is implemented here—this is a plan for the
orchestrator to execute.

## Current behavior (reference)

- The `sync-opencode` alias is defined in `.bashrc` and runs the remote setup
  script via `curl -fsSL … | bash` (see `~/.bashrc`, lines ~109-113); the script
  lives at `.config/opencode/setup.sh` in the repo.
- The setup script (`.config/opencode/setup.sh`) clones the repo into a temp
  dir, rsyncs `.config/opencode/` into `$HOME/.config/opencode`, preserves
  `.secrets/`, and injects the alias into the shell rc; it already switches to
  `.zshrc` on macOS via `$OSTYPE` (see lines ~117-134 for alias injection and
  shell detection).
- A prior cron pattern exists in `init_vm()` (`~/.bashrc`, lines ~124-128)
  showing the repo uses `crontab -l` with grep to avoid duplicate entries; this
  pattern can be reused.

## Requirements

- Cross-platform scheduling: cron on Linux; launchd user agent on macOS (cron
  on macOS is discouraged and unreliable after sleep).
- Idempotent install/remove/status commands; no duplicate entries.
- User-level only (no root/system units).
- Minimal, explicit environment (PATH set; no reliance on shell rc); safe even
  when running headless.
- Concurrency safety (skip if already running) and reasonable defaults for
  frequency.
- Logging with rotation/truncation to avoid unbounded growth.
- Security: avoid executing partially downloaded scripts; prefer
  download-then-verify-then-run.

## Proposed approach

1) **Local wrapper script**: `~/.config/opencode/sync-opencode-scheduled.sh`

   - Set explicit `PATH` (include `/usr/local/bin`, `/opt/homebrew/bin`,
     `/usr/bin`, `/bin`).
   - Ensure `HOME` is correct (via `getent` on Linux or `dscl` fallback on
     macOS) and create `~/.local/state/sync-opencode/`.
   - Download the remote setup script to a temp file with
     `curl -fsSL --max-time 30`.
   - Syntax-check the download (`bash -n`); optionally checksum-verify if a
     pinned SHA or checksum file is provided.
   - Execute with a timeout (e.g., 300s) and log timestamped success/failure to
     `~/.local/state/sync-opencode/sync.log`; rotate or truncate when large
     (e.g., >1MB).
   - Clean up the temp file; exit non-zero on failures.

2) **Scheduler management subcommands** (extend `.config/opencode/setup.sh` or
   add a small helper):

   - `--schedule-install [--interval <seconds|cron-spec>]`
   - `--schedule-remove`
   - `--schedule-status`
   - Detect OS via `$OSTYPE` (already used in setup.sh) and branch to launchd
     vs cron.

3) **Linux (cron) details**

   - Default interval: every 4 hours (`0 */4 * * *`); allow override.
   - Crontab line example:

     ```bash
     0 */4 * * * /usr/bin/flock -n /tmp/sync-opencode.lock /bin/bash -c \
       'PATH=/usr/local/bin:/usr/bin:/bin; \
       ~/.config/opencode/sync-opencode-scheduled.sh' \
       >> ~/.local/state/sync-opencode/cron.log 2>&1
     ```

   - Duplicate prevention: before adding, check
     `crontab -l 2>/dev/null | grep -F sync-opencode`; add via:

     ```bash
     (crontab -l 2>/dev/null | grep -v sync-opencode; \
      echo "<entry>") | crontab -
     ```

   - Removal: filter out the marker line and re-install crontab.
   - Concurrency: use `flock -n` to skip if already running (flock is
     Linux-only; acceptable since macOS uses launchd).
   - PATH: set inline in the crontab entry to avoid minimal cron environments.

4) **macOS (launchd) details**

   - Create `~/Library/LaunchAgents/ai.one-ring.sync-opencode.plist`
     (user agent).
   - Keys:

     - `Label`: `ai.one-ring.sync-opencode`
     - `ProgramArguments`: `[/bin/bash, -c,
       "PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin; ~/.config/opencode/sync-opencode-scheduled.sh"]`
     - `StartInterval`: default `14400` (4 hours); allow override. Optionally
       support `StartCalendarInterval` for fixed times.
     - `StandardOutPath` and `StandardErrorPath`:
       `~/.local/state/sync-opencode/stdout.log` and `stderr.log`.
     - Optional `EnvironmentVariables` with explicit PATH.

   - Install: write plist → `launchctl bootout gui/$(id -u)/ai.one-ring.sync-opencode`
     (ignore failure) → `launchctl bootstrap gui/$(id -u) <plist>`.
   - Remove: `launchctl bootout gui/$(id -u)/ai.one-ring.sync-opencode` then
     delete the plist.
   - Status: `launchctl print gui/$(id -u)/ai.one-ring.sync-opencode`.

5) **Security and safety**

   - Prefer pinning to a commit SHA URL or publish a checksum file and verify
     before execution.
   - Always download-then-run (no direct `curl | bash` in scheduled context).
   - Use `--max-time` and an overall `timeout` to avoid hangs.
   - Fail fast on empty downloads or syntax errors.
   - Logging makes failures diagnosable; truncate or rotate to prevent
     unbounded growth.

6) **Testing and validation**

   - Linux: verify crontab entry creation/removal; run the wrapper once
     manually; confirm `flock` prevents overlap; inspect logs; test on at least
     Debian/Ubuntu and Fedora (cron present by default). Consider Alpine/BusyBox
     note: `flock` may be absent—document fallback or warning.
   - macOS: bootstrap the agent on both Intel (`/usr/local/bin`) and Apple
     Silicon (`/opt/homebrew/bin`); verify `StartInterval` triggers; inspect
     logs; test sleep/wake to ensure launchd fires post-wake.
   - Ensure rsync behavior remains unchanged (existing `--delete` semantics
     still apply).

7) **Rollback/uninstall**

   - Provide `--schedule-remove` to clean the crontab entry or bootout+delete
     the plist.
   - Consider adding to `uninstall.sh` so teardown removes schedulers.

8) **Release-based sync flow (checksum-first)**

   - Source of truth: release assets (not branch `main`). Each release publishes
     `setup.sh` and `setup.sh.sha256` as assets. Channels: `main` (stable),
     `beta`, `alpha`.
   - Wrapper logic per run:
     1. Decide the channel (e.g., stable = latest from `main`; optionally allow
        `beta`/`alpha`).
     2. Fetch the latest tag for that channel (via GitHub Releases API or known
        tag name); build URLs like
        `https://github.com/one-ring-ai/dotfiles/releases/download/<tag>/setup.sh`
        and `.../setup.sh.sha256`.
     3. Download both files to temp; verify with
        `sha256sum --check setup.sh.sha256` (fail-fast if mismatch or empty).
     4. If OK, run `bash setup.sh` with timeout and logging.
     5. Log success/failure; if checksum fails or download fails, do not run.
   - Outcome: the client aligns `$HOME/.config/opencode` to the released
     version, with integrity verified. No `curl | bash` from moving branches.

## Operational usage (post-implementation)

- Initial one-time sync (manual):

  ```bash
  sync-opencode
  ```

- Install scheduler (user-level):

  ```bash
  ~/.config/opencode/sync-opencode-scheduled.sh --schedule-install --channel stable
  ```

  - macOS: installs a launchd agent in `~/Library/LaunchAgents`.
  - Linux: installs a cron entry in the user crontab with `flock` and PATH set.
  - Channels: `--channel stable` (default, main); `--channel beta` or
    `--channel alpha` for prerelease tracks.

- Remove scheduler:

  ```bash
  ~/.config/opencode/sync-opencode-scheduled.sh --schedule-remove
  ```

- Check status:

  ```bash
  ~/.config/opencode/sync-opencode-scheduled.sh --schedule-status
  ```

- Runtime behavior on each scheduled run:
  - Fetch latest release tag for the chosen channel.
  - Download `setup.sh` and `setup.sh.sha256` from release assets.
  - Verify checksum (`sha256sum --check`); only if OK, execute `bash setup.sh`
    with timeout and logging under `~/.local/state/sync-opencode/`.

## Complexity assessment

- **Overall**: Moderate. The work touches cross-platform scheduling,
  environment isolation, and safety/locking, but reuses existing patterns in
  the repo (cron idempotency in `init_vm`). Most complexity lies in macOS
  launchd plist handling and a robust download/verify/log wrapper.
- **Risk areas**: PATH quirks (Homebrew), `flock` availability on minimal
  distros, and safety around repeated `curl` of a remote script; mitigations are
  clear and limited in scope.

## Open questions for alignment

- Acceptable default interval? (Proposed: 4h; alternative: daily 03:00 local.)
- Should we pin to a commit SHA or add checksum verification? (Recommended for
  scheduled runs.)
- Do we need a user-facing toggle in setup (prompt/flag) or always enable
  scheduling?
- Should we also support systemd user timers on systemd hosts as an optional
  alternative to cron?

## Next steps (for the orchestrator)

1) Implement the wrapper script in `~/.config/opencode/sync-opencode-scheduled.sh`
   with download/verify/execute/log/rotate.
2) Add scheduler management subcommands (`--schedule-install/remove/status`) to
   `.config/opencode/setup.sh` (or a helper), following the cron/launchd details
   above.
3) Hook optional install at the end of setup (opt-in flag or prompt); ensure
   uninstall removes schedulers.
4) Test on Linux (cron) and macOS (launchd) as outlined; document known
   limitations (`flock` on Alpine).
