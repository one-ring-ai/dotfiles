#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${HOME}/.config"
readonly FONT_DIR="${HOME}/.local/share/fonts"
readonly DOTFILES_REPO="https://github.com/one-ring-ai/dotfiles.git"
readonly DOTFILES_DIR="${HOME}/dotfiles"
readonly TRIVY_VERSION="0.55.2"
readonly TRIVY_CACHE_DIR="${HOME}/.cache/trivy"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

PACKAGE_MANAGER=""
PRIVILEGE_CMD=""

log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_root() {
    [ "$(id -u)" -eq 0 ]
}

get_user_home() {
    if [ -n "${SUDO_USER:-}" ]; then
        getent passwd "$SUDO_USER" | cut -d: -f6
    else
        echo "$HOME"
    fi
}

detect_package_manager() {
    local managers="nala apt dnf yum pacman zypper emerge xbps-install nix-env"
    
    for manager in $managers; do
        if command_exists "$manager"; then
            PACKAGE_MANAGER="$manager"
            log_info "Detected package manager: $manager"
            return 0
        fi
    done

    log_error "No supported package manager found"
    return 1
}

detect_privilege_escalation() {
    if command_exists sudo; then
        PRIVILEGE_CMD="sudo"
    elif command_exists doas && [ -f "/etc/doas.conf" ]; then
        PRIVILEGE_CMD="doas"
    else
        PRIVILEGE_CMD="su -c"
    fi
    log_info "Using privilege escalation: $PRIVILEGE_CMD"
}

validate_requirements() {
    local requirements="curl git"
    local missing=""
    
    for req in $requirements; do
        if ! command_exists "$req"; then
            missing="$missing $req"
    fi
    done

    if [ -n "$missing" ]; then
        log_error "Missing required commands:$missing"
        return 1
    fi
    
    return 0
}

validate_permissions() {
    if ! groups | grep -qE "(wheel|sudo|root)"; then
        log_error "User must be in wheel, sudo, or root group"
        return 1
    fi

    if [ ! -w "$SCRIPT_DIR" ]; then
        log_error "No write permission to script directory: $SCRIPT_DIR"
        return 1
    fi
    
    return 0
}

clone_or_update_dotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        log_info "Dotfiles repository already exists, force updating..."
        cd "$DOTFILES_DIR"
        git fetch origin
        git reset --hard origin/main
        log_info "Local changes overwritten with latest version"
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    fi
}

setup_directories() {
    log_info "Setting up directories..."
    
    mkdir -p "$CONFIG_DIR" "$FONT_DIR"
    
    log_info "Working from directory: $DOTFILES_DIR"
}

install_packages() {
    local packages="bash bash-completion tar bat tree wget unzip fontconfig"
    if ! command_exists nvim; then
        packages="$packages neovim"
        fi
    if ! command_exists trash; then
        packages="$packages trash-cli"
        fi
    
    log_info "Installing packages: $packages"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            install_arch_packages "$packages"
            ;;
        nala|apt)
            $PRIVILEGE_CMD $PACKAGE_MANAGER update
            $PRIVILEGE_CMD $PACKAGE_MANAGER install -y $packages
            ;;
        dnf|yum)
            $PRIVILEGE_CMD $PACKAGE_MANAGER install -y $packages
            ;;
        emerge)
            local emerge_packages="app-shells/bash app-shells/bash-completion app-arch/tar sys-apps/bat app-text/tree app-misc/trash-cli"
            if ! command_exists nvim; then
                emerge_packages="$emerge_packages app-editors/neovim"
    fi
            $PRIVILEGE_CMD $PACKAGE_MANAGER -v $emerge_packages
            ;;
        xbps-install)
            $PRIVILEGE_CMD $PACKAGE_MANAGER -Sy $packages
            ;;
        nix-env)
            local nix_packages="nixos.bash nixos.bash-completion nixos.gnutar nixos.bat nixos.tree nixos.trash-cli"
            if ! command_exists nvim; then
                nix_packages="$nix_packages nixos.neovim"
        fi
            $PRIVILEGE_CMD $PACKAGE_MANAGER -iA $nix_packages
            ;;
        zypper)
            $PRIVILEGE_CMD $PACKAGE_MANAGER install -y $packages
            ;;
        *)
            log_error "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

install_arch_packages() {
    local packages="$1"
    local aur_helper=""
    
    if command_exists yay; then
        aur_helper="yay"
    elif command_exists paru; then
        aur_helper="paru"
    else
        log_info "Installing yay AUR helper..."
        $PRIVILEGE_CMD pacman -S --needed --noconfirm base-devel git
        
        local temp_dir
        temp_dir=$(mktemp -d)
        cd "$temp_dir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        aur_helper="yay"
    fi
    
    log_info "Installing packages with $aur_helper..."
    $aur_helper -S --needed --noconfirm $packages
}

install_nerd_font() {
    local font_name="MesloLGS Nerd Font"
    
    if fc-list | grep -qi "meslo"; then
        log_info "Nerd font already installed"
        return 0
fi
    log_info "Installing $font_name..."
    
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if wget -q "$font_url" -O "$temp_dir/Meslo.zip"; then
        unzip -q "$temp_dir/Meslo.zip" -d "$temp_dir"
        mkdir -p "$FONT_DIR/MesloLGS"
        find "$temp_dir" -name "*.ttf" -exec mv {} "$FONT_DIR/MesloLGS/" \;
        fc-cache -fv >/dev/null 2>&1
        log_success "Font installed successfully"
    else
        log_warning "Failed to download font"
    fi
    
    rm -rf "$temp_dir"
}

install_starship() {
    if command_exists starship; then
        log_info "Starship already installed"
        return 0
    fi
    
    log_info "Installing Starship prompt..."
    if curl -sS https://starship.rs/install.sh | $PRIVILEGE_CMD sh -s -- -y; then
        log_success "Starship installed successfully"
    else
        log_error "Failed to install Starship"
        return 1
    fi
}

install_fzf() {
    if command_exists fzf; then
        log_info "FZF already installed"
        return 0
    fi
    
    local fzf_dir="$HOME/.fzf"
    
    if [ -d "$fzf_dir" ]; then
        log_info "FZF directory exists, updating..."
        cd "$fzf_dir" && git pull
    else
        log_info "Installing FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
    fi
    
    "$fzf_dir/install" --all --no-update-rc
    log_success "FZF installed successfully"
}

install_zoxide() {
    if command_exists zoxide; then
        log_info "Zoxide already installed"
        return 0
    fi

    log_info "Installing Zoxide..."
    if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        log_success "Zoxide installed successfully"
    else
        log_error "Failed to install Zoxide"
        return 1
    fi
}

install_trivy() {
    if command_exists trivy; then
        local current_version
        current_version=$(trivy --version | awk 'NR==1 {print $2}')
        if [ "$current_version" = "$TRIVY_VERSION" ]; then
            log_info "Trivy $TRIVY_VERSION already installed"
            return 0
        fi
    fi

    log_info "Installing Trivy $TRIVY_VERSION..."
    local temp_dir archive base_url trivy_binary
    temp_dir=$(mktemp -d)
    archive="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
    base_url="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"

    if ! curl -sS "$base_url/$archive" -o "$temp_dir/$archive"; then
        log_error "Failed to download Trivy archive"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! curl -sS "$base_url/$archive.sha256" -o "$temp_dir/$archive.sha256"; then
        log_error "Failed to download Trivy checksum"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! (cd "$temp_dir" && sha256sum -c "$archive.sha256"); then
        log_error "Checksum verification failed for Trivy"
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$temp_dir/$archive" -C "$temp_dir"
    trivy_binary="$temp_dir/trivy"

    if [ ! -f "$trivy_binary" ]; then
        log_error "Trivy binary not found after extraction"
        rm -rf "$temp_dir"
        return 1
    fi

    if [ -n "${PRIVILEGE_CMD:-}" ]; then
        $PRIVILEGE_CMD install -m 0755 "$trivy_binary" /usr/local/bin/trivy
    else
        install -m 0755 "$trivy_binary" /usr/local/bin/trivy
    fi

    mkdir -p "$TRIVY_CACHE_DIR"

    if TRIVY_CACHE_DIR="$TRIVY_CACHE_DIR" trivy plugin list | grep -q '^mcp '; then
        log_info "Trivy mcp plugin already installed"
    else
        if TRIVY_CACHE_DIR="$TRIVY_CACHE_DIR" trivy plugin install mcp; then
            log_success "Trivy mcp plugin installed"
        else
            log_warning "Failed to install Trivy mcp plugin"
        fi
    fi

    rm -rf "$temp_dir"
    log_success "Trivy $TRIVY_VERSION installed successfully"
}


setup_config_directory() {

    local user_home
    user_home=$(get_user_home)
    local user_config_dir="$user_home/.config"

    if [ -d "$DOTFILES_DIR/.config" ]; then
        log_info "Setting up .config directory..."
        mkdir -p "$user_config_dir"

        for config_item in "$DOTFILES_DIR/.config"/*; do
            if [ -e "$config_item" ]; then
                local item_name
                item_name=$(basename "$config_item")
                local target="$user_config_dir/$item_name"

                if [ -e "$target" ]; then
                    log_info "Backing up existing $item_name"
                    mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
                fi

                cp -r "$config_item" "$target"
                log_info "Copied $item_name configuration"
            fi
        done

        log_success ".config directory setup completed"
    else
        log_warning ".config directory not found in dotfiles"
    fi
}

setup_bash_config() {
    local user_home
    user_home=$(get_user_home)
    local bashrc="$user_home/.bashrc"
    local bash_profile="$user_home/.bash_profile"
    local starship_config="$user_home/.config/starship.toml"
    
    if [ -f "$bashrc" ]; then
        log_info "Backing up existing .bashrc"
        mv "$bashrc" "$bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ -f "$DOTFILES_DIR/.bashrc" ]; then
        ln -sf "$DOTFILES_DIR/.bashrc" "$bashrc"
        log_success "Bashrc configuration linked"
    else
        log_error "Bashrc template not found"
        return 1
    fi

    local quickstart_guide="$user_home/quickstart_guide.md"
    if [ -f "$DOTFILES_DIR/quickstart_guide.md" ]; then
        if [ -f "$quickstart_guide" ]; then
            log_info "Backing up existing quickstart_guide.md"
            mv "$quickstart_guide" "$quickstart_guide.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        cp "$DOTFILES_DIR/quickstart_guide.md" "$quickstart_guide"
        log_success "Quickstart guide copied to home directory"
    else
        log_error "Quickstart guide template not found"
        return 1
    fi

    if [ -f "$DOTFILES_DIR/starship.toml" ]; then
        ln -sf "$DOTFILES_DIR/starship.toml" "$starship_config"
        log_success "Starship configuration linked"
    else
        log_warning "Starship config template not found"
    fi
    
    if [ ! -f "$bash_profile" ]; then
        cat > "$bash_profile" << 'EOF'
# Source bashrc if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF
        log_success "Created .bash_profile"
    fi
}

main() {
    log_info "Starting Dotfiles setup..."
    
    validate_requirements || exit 1
    validate_permissions || exit 1
    
    detect_package_manager || exit 1
    detect_privilege_escalation
    
    clone_or_update_dotfiles || exit 1
    setup_directories || exit 1
    
    install_packages || exit 1
    install_nerd_font
    install_starship || exit 1
    install_fzf || exit 1
    install_zoxide || exit 1
    install_trivy || exit 1
    setup_config_directory
    setup_bash_config || exit 1
    
    log_success "Dotfiles setup completed successfully!"
    log_info "Please restart your shell or run 'source ~/.bashrc' to apply changes"
}

main "$@"