#!/usr/bin/env bash

set -euo pipefail

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

determine_user_home() {
    local -r current_user="${USER:-$(id -u -n)}"
    local user_home
    local home_owner
    
    if [ -n "${HOME:-}" ]; then
        home_owner=$(stat -c %U "$HOME" 2>/dev/null || true)
        if [ -n "$home_owner" ] && [ "$home_owner" = "$current_user" ]; then
            user_home="$HOME"
        fi
    fi
    
    if [ -z "${user_home:-}" ]; then
        user_home=$(getent passwd "$current_user" 2>/dev/null | cut -d: -f6 || true)
    fi
    
    if [ -z "$user_home" ] || [ "$user_home" = "~" ] || [[ "$user_home" == ~* ]]; then
        if [ -n "$user_home" ] && [ "$user_home" != "~" ] && [[ "$user_home" == ~* ]]; then
            user_home=$(eval echo "$user_home" 2>/dev/null || echo "")
        fi
        if [ -z "$user_home" ] || [ "$user_home" = "~" ] || [[ "$user_home" == ~* ]]; then
            print_error "Could not determine home directory for user: $current_user"
            exit 1
        fi
    fi
    
    echo "$user_home"
}

check_dependencies() {
    local missing_deps=()
    
    for cmd in curl git rsync mktemp; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

cleanup_temp_dir() {
    if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

main() {
    check_dependencies
    
    local user_home
    user_home=$(determine_user_home)
    
    readonly TARGET_DIR="$user_home/.config/opencode"
    readonly TEMP_DIR=$(mktemp -d)
    
    trap cleanup_temp_dir EXIT
    
    print_info "Target directory: $TARGET_DIR"
    print_info "Cloning repository..."
    
    if ! git clone --depth 1 https://github.com/one-ring-ai/dotfiles.git "$TEMP_DIR"; then
        print_error "Failed to clone repository"
        exit 1
    fi
    
    readonly SOURCE_DIR="$TEMP_DIR/.config/opencode"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        print_error "Source directory not found in repository"
        exit 1
    fi
    
    local secrets_existed=false
    if [ -d "$TARGET_DIR/.secrets" ]; then
        secrets_existed=true
    fi
    
    print_info "Creating directories..."
    mkdir -p "$TARGET_DIR" "$TARGET_DIR/.secrets"
    
    print_info "Copying configuration files..."
    if ! rsync -av --delete --exclude=.secrets "$SOURCE_DIR/" "$TARGET_DIR/"; then
        print_error "Failed to copy configuration files"
        exit 1
    fi
    
    if [ "$secrets_existed" = true ]; then
        print_info "Existing secrets were preserved"
    fi
    
    print_info "Adding sync-opencode alias to ~/.bashrc..."
    local bashrc_file="$user_home/.bashrc"
    local alias_line="alias sync-opencode='curl -fsSL https://raw.githubusercontent.com/one-ring-ai/dotfiles/main/.config/opencode/setup.sh | bash'"
    
    if [ ! -f "$bashrc_file" ]; then
        touch "$bashrc_file"
    fi
    
    if ! grep -Fq "$alias_line" "$bashrc_file"; then
        echo "$alias_line" >> "$bashrc_file"
        print_info "Alias added to ~/.bashrc"
    else
        print_info "Alias already exists in ~/.bashrc"
    fi
    
    print_info "Setup completed successfully"
    echo
    print_info "Please create the following files in $TARGET_DIR/.secrets/:"
    echo "- figma-token"
    echo "- openrouter-key"
    echo
    print_info "After creating the files, secure them with:"
    echo "chmod 600 $TARGET_DIR/.secrets/figma-token $TARGET_DIR/.secrets/openrouter-key"
}

main "$@"