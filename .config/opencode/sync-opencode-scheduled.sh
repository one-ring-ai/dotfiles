#!/usr/bin/env bash

set -euo pipefail

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${PATH:-}"

readonly STATE_DIR="$HOME/.local/state/sync-opencode"
readonly DOWNLOAD_DIR="$STATE_DIR/downloads"
readonly SYNC_LOG="$STATE_DIR/sync.log"
readonly CRON_LOG="$STATE_DIR/cron.log"
readonly STDOUT_LOG="$STATE_DIR/stdout.log"
readonly STDERR_LOG="$STATE_DIR/stderr.log"
readonly LOCK_FILE="$STATE_DIR/sync.lock"
readonly PID_FILE="$STATE_DIR/sync.pid"
readonly PLIST_PATH="$HOME/Library/LaunchAgents/ai.one-ring.sync-opencode.plist"
readonly GITHUB_API="https://api.github.com/repos/one-ring-ai/dotfiles/releases"
readonly MAX_LOG_SIZE=1048576

CHANNEL="stable"
INTERVAL=""
SCHEDULE_INSTALL=false
SCHEDULE_REMOVE=false
SCHEDULE_STATUS=false

log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted="[$timestamp] $message"
    echo "$formatted"
    echo "$formatted" >> "$SYNC_LOG"
}

rotate_log() {
    local log_file="$1"
    if [ -f "$log_file" ] && [ "$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)" -ge "$MAX_LOG_SIZE" ]; then
        mv "$log_file" "$log_file.1"
        : > "$log_file"
    fi
}

init_state_dir() {
    mkdir -p "$STATE_DIR"
    mkdir -p "$DOWNLOAD_DIR"
    rotate_log "$SYNC_LOG"
    rotate_log "$CRON_LOG"
    rotate_log "$STDOUT_LOG"
    rotate_log "$STDERR_LOG"
}

acquire_lock() {
    if command -v flock >/dev/null 2>&1; then
        exec 200>"$LOCK_FILE"
        if ! flock -n 200; then
            log_message "Another sync is running, skipping"
            exit 0
        fi
    else
        if [ -f "$PID_FILE" ]; then
            local pid
            pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                log_message "Another sync is running (PID: $pid), skipping"
                exit 0
            fi
        fi
        echo $$ > "$PID_FILE"
    fi
}

release_lock() {
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
}

sha256_verify() {
    local checksum_file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum --check "$checksum_file" >/dev/null 2>&1
    else
        shasum -a 256 --check "$checksum_file" >/dev/null 2>&1
    fi
}

get_release_tag() {
    local channel="$1"
    local python_cmd
    if command -v python3 >/dev/null 2>&1; then
        python_cmd="python3"
    elif command -v python >/dev/null 2>&1; then
        python_cmd="python"
    else
        log_message "Error: Python is required but not installed"
        exit 1
    fi

    local releases_json
    releases_json=$(curl -fsSL "$GITHUB_API" 2>/dev/null) || {
        log_message "Error: Failed to fetch releases from GitHub API"
        exit 1
    }

    local tag=""
    if [ "$channel" = "stable" ]; then
        tag=$(echo "$releases_json" | "$python_cmd" -c '
import json, sys
try:
    releases = json.load(sys.stdin)
    for r in releases:
        if not r.get("prerelease", False):
            print(r.get("tag_name", ""))
            break
except:
    pass
' 2>/dev/null)
    else
        tag=$(echo "$releases_json" | "$python_cmd" -c '
import json, sys
channel = sys.argv[1]
try:
    releases = json.load(sys.stdin)
    for r in releases:
        if r.get("prerelease", False):
            tag = r.get("tag_name", "")
            name = r.get("name", "")
            if channel.lower() in tag.lower() or channel.lower() in name.lower():
                print(tag)
                break
except:
    pass
' "$channel" 2>/dev/null)
    fi

    if [ -z "$tag" ]; then
        log_message "Error: No release found for channel: $channel"
        exit 1
    fi

    echo "$tag"
}

download_and_verify() {
    local tag="$1"
    local setup_url="https://github.com/one-ring-ai/dotfiles/releases/download/$tag/setup.sh"
    local checksum_url="https://github.com/one-ring-ai/dotfiles/releases/download/$tag/setup.sh.sha256"
    local setup_path="$DOWNLOAD_DIR/setup.sh"
    local checksum_path="$DOWNLOAD_DIR/setup.sh.sha256"

    rm -f "$setup_path" "$checksum_path"

    log_message "Downloading setup.sh from release $tag..."
    if ! curl -fL --retry 3 --retry-delay 2 -o "$setup_path" "$setup_url" 2>/dev/null; then
        log_message "Error: Failed to download setup.sh"
        rm -f "$setup_path" "$checksum_path"
        return 1
    fi

    if [ ! -s "$setup_path" ]; then
        log_message "Error: Downloaded setup.sh is empty"
        rm -f "$setup_path" "$checksum_path"
        return 1
    fi

    log_message "Downloading checksum file..."
    if ! curl -fL --retry 3 --retry-delay 2 -o "$checksum_path" "$checksum_url" 2>/dev/null; then
        log_message "Error: Failed to download checksum file"
        rm -f "$setup_path" "$checksum_path"
        return 1
    fi

    log_message "Verifying checksum..."
    if ! (cd "$DOWNLOAD_DIR" && sha256_verify setup.sh.sha256); then
        log_message "Error: Checksum verification failed"
        rm -f "$setup_path" "$checksum_path"
        return 1
    fi

    log_message "Checksum verified successfully"
    chmod +x "$setup_path"
    echo "$DOWNLOAD_DIR"
}

run_setup() {
    local setup_path="$1"
    log_message "Executing setup.sh..."

    local timeout_cmd=""
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 300"
    elif command -v gtimeout >/dev/null 2>&1; then
        timeout_cmd="gtimeout 300"
    fi

    if [ -n "$timeout_cmd" ]; then
        if $timeout_cmd bash "$setup_path" >> "$STDOUT_LOG" 2>> "$STDERR_LOG"; then
            log_message "Setup completed successfully"
            return 0
        else
            log_message "Error: Setup failed or timed out"
            return 1
        fi
    else
        if bash "$setup_path" >> "$STDOUT_LOG" 2>> "$STDERR_LOG"; then
            log_message "Setup completed successfully"
            return 0
        else
            log_message "Error: Setup failed"
            return 1
        fi
    fi
}

seconds_to_cron() {
    local seconds="$1"
    if [ "$seconds" -ge 3600 ]; then
        local hours=$((seconds / 3600))
        if [ "$hours" -gt 23 ]; then
            hours=24
        fi
        echo "0 */$hours * * *"
    elif [ "$seconds" -ge 60 ]; then
        local minutes=$((seconds / 60))
        if [ "$minutes" -gt 59 ]; then
            minutes=59
        fi
        echo "*/$minutes * * * *"
    else
        echo "*/5 * * * *"
    fi
}

install_cron() {
    local channel="$1"
    local interval="${2:-0 */4 * * *}"
    local cron_spec

    if [[ "$interval" =~ ^[0-9]+$ ]]; then
        if [ "$interval" -lt 60 ]; then
            cron_spec="*/5 * * * *"
        else
            cron_spec=$(seconds_to_cron "$interval")
        fi
    else
        cron_spec="$interval"
    fi

    local script_path
    script_path="$HOME/.config/opencode/sync-opencode-scheduled.sh"
    local cron_line="$cron_spec $script_path --channel $channel >> $CRON_LOG 2>&1"

    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || true)

    local filtered_crontab
    filtered_crontab=$(echo "$current_crontab" | grep -v "sync-opencode-scheduled.sh" || true)

    local new_crontab
    new_crontab="$filtered_crontab
$cron_line"

    echo "$new_crontab" | crontab -
    log_message "Cron job installed: $cron_spec with channel $channel"
}

remove_cron() {
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || true)
    local filtered_crontab
    filtered_crontab=$(echo "$current_crontab" | grep -v "sync-opencode-scheduled.sh" || true)
    echo "$filtered_crontab" | crontab -
    log_message "Cron job removed"
}

cron_status() {
    if crontab -l 2>/dev/null | grep -q "sync-opencode-scheduled.sh"; then
        log_message "Cron job is installed"
        crontab -l | grep "sync-opencode-scheduled.sh"
        return 0
    else
        log_message "No cron job found"
        return 1
    fi
}

install_launchd() {
    local channel="$1"
    local interval="${2:-14400}"

    if [[ "$interval" =~ ^[0-9]+$ ]]; then
        if [ "$interval" -lt 60 ]; then
            interval=300
        fi
    else
        interval=14400
    fi

    local script_path
    script_path="$HOME/.config/opencode/sync-opencode-scheduled.sh"

    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.one-ring.sync-opencode</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"; $script_path --channel $channel</string>
    </array>
    <key>StartInterval</key>
    <integer>$interval</integer>
    <key>StandardOutPath</key>
    <string>$STDOUT_LOG</string>
    <key>StandardErrorPath</key>
    <string>$STDERR_LOG</string>
</dict>
</plist>
EOF

    launchctl bootout gui/$(id -u)/ai.one-ring.sync-opencode 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) "$PLIST_PATH" 2>/dev/null || {
        log_message "Error: Failed to load launchd job"
        return 1
    }
    log_message "Launchd job installed with interval ${interval}s and channel $channel"
}

remove_launchd() {
    launchctl bootout gui/$(id -u)/ai.one-ring.sync-opencode 2>/dev/null || true
    rm -f "$PLIST_PATH"
    log_message "Launchd job removed"
}

launchd_status() {
    if [ -f "$PLIST_PATH" ]; then
        log_message "Launchd job is installed at: $PLIST_PATH"
        launchctl print gui/$(id -u)/ai.one-ring.sync-opencode 2>/dev/null || {
            log_message "Warning: Plist exists but job may not be loaded"
            return 1
        }
        return 0
    else
        log_message "No launchd job found"
        return 1
    fi
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --channel)
                if [ $# -lt 2 ]; then
                    log_message "Error: --channel requires an argument"
                    exit 1
                fi
                CHANNEL="$2"
                if [ "$CHANNEL" != "stable" ] && [ "$CHANNEL" != "beta" ] && [ "$CHANNEL" != "alpha" ]; then
                    log_message "Error: Invalid channel: $CHANNEL (must be stable, beta, or alpha)"
                    exit 1
                fi
                shift 2
                ;;
            --schedule-install)
                SCHEDULE_INSTALL=true
                shift
                ;;
            --schedule-remove)
                SCHEDULE_REMOVE=true
                shift
                ;;
            --schedule-status)
                SCHEDULE_STATUS=true
                shift
                ;;
            --interval)
                if [ $# -lt 2 ]; then
                    log_message "Error: --interval requires an argument"
                    exit 1
                fi
                INTERVAL="$2"
                shift 2
                ;;
            -*)
                log_message "Error: Unknown option: $1"
                exit 1
                ;;
            *)
                log_message "Error: Unknown argument: $1"
                exit 1
                ;;
        esac
    done
}

run_sync() {
    init_state_dir
    acquire_lock
    trap release_lock EXIT

    log_message "Starting sync for channel: $CHANNEL"

    local tag
    tag=$(get_release_tag "$CHANNEL")
    log_message "Found release tag: $tag"

    local download_dir
    if ! download_dir=$(download_and_verify "$tag"); then
        log_message "Sync failed: download or verification error"
        return 1
    fi

    local setup_path="$download_dir/setup.sh"
    if run_setup "$setup_path"; then
        log_message "Sync completed successfully"
        return 0
    else
        log_message "Sync failed: setup execution error"
        return 1
    fi
}

handle_schedule() {
    if [ "$SCHEDULE_REMOVE" = true ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            remove_launchd
        else
            remove_cron
        fi
        return 0
    fi

    if [ "$SCHEDULE_STATUS" = true ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            launchd_status
        else
            cron_status
        fi
        return 0
    fi

    if [ "$SCHEDULE_INSTALL" = true ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_launchd "$CHANNEL" "$INTERVAL"
        else
            install_cron "$CHANNEL" "$INTERVAL"
        fi
        return 0
    fi

    return 1
}

main() {
    parse_args "$@"

    if [ "$SCHEDULE_REMOVE" = true ] || [ "$SCHEDULE_STATUS" = true ] || [ "$SCHEDULE_INSTALL" = true ]; then
        init_state_dir
        handle_schedule
        exit 0
    fi

    run_sync
}

main "$@"
