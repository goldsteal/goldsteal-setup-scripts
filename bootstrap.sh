#!/usr/bin/env bash
# bootstrap.sh — single-folder bootstrap
set -euo pipefail

# Detect repo folder
REPO_DIR=$(dirname "$(realpath "$0")")
export PATH="$REPO_DIR:$PATH"

TARGET_USER=${TARGET_USER:-goldsteal}
USER_HOME=$(eval echo "~$TARGET_USER")

ask() {
    read -rp "$1 [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

install_if_missing() {
    local pkg=$1
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "[*] Installing $pkg..."
        sudo brl fetch "$pkg" || sudo pacman -S --noconfirm "$pkg" || sudo apt install -y "$pkg"
    fi
}

safe_run_config() {
    local script=$1
    local desc=$2
    if [[ -f "$script" ]]; then
        if ask "Run $desc configuration from $script?"; then
            "$script"
        else
            echo "[!] Skipped $desc config."
        fi
    else
        echo "[!] Warning: Missing $script (expected for $desc). Continuing..."
    fi
}

# -----------------------
# Step 1: Bedrock check
# -----------------------
if ! command -v brl >/dev/null 2>&1; then
    echo "[!] Bedrock Linux not detected."
    if ask "Do you want to install Bedrock Linux?"; then
        curl -o bedrock-installer https://github.com/bedrocklinux/bedrocklinux-userland/releases/latest/download/bedrock-installer
        chmod +x bedrock-installer
        sudo ./bedrock-installer
        echo "[*] Reboot required after Bedrock install!"
        exit 0
    else
        echo "[!] Cannot continue without Bedrock."
        exit 1
    fi
fi
echo "[+] Bedrock detected."

# -----------------------
# Step 2: Optional strata
# -----------------------
if ask "Configure recommended strata (Arch, Debian, Fedora)?"; then
    sudo brl fetch arch
    sudo brl fetch debian
    sudo brl fetch fedora
fi

# -----------------------
# Step 3: Common tools
# -----------------------
COMMON_PKGS=(zsh tmux curl wget git)
WAYLAND_PKGS=(foot sway)
X11_PKGS=(alacritty i3)

for pkg in "${COMMON_PKGS[@]}"; do
    install_if_missing "$pkg"
done

SESSION_TYPE=${XDG_SESSION_TYPE:-}
if [[ "$SESSION_TYPE" == "wayland" ]]; then
    for pkg in "${WAYLAND_PKGS[@]}"; do
        install_if_missing "$pkg"
    done
else
    for pkg in "${X11_PKGS[@]}"; do
        install_if_missing "$pkg"
    done
fi

# -----------------------
# Step 3b: yay (Arch only)
# -----------------------
if brl which -s pacman >/dev/null 2>&1; then
    if ask "Install yay in Arch stratum?"; then
        sudo brl sh -c 'pacman -Sy --noconfirm --needed base-devel git'
        sudo brl sh -c 'cd /tmp && rm -rf yay && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'
    fi
fi

# -----------------------
# Step 4: Configs
# -----------------------
safe_run_config "$REPO_DIR/colors.sh" "color palette"
safe_run_config "$REPO_DIR/term.sh --install" "term launcher"
safe_run_config "$REPO_DIR/wm-setup.sh" "Window Manager (i3/sway) + vim-like keybindings"

# -----------------------
# Step 5: SSH
# -----------------------
sudo "$REPO_DIR/ssh-setup.sh"

# -----------------------
# Step 6: Set zsh default shell
# -----------------------
if [[ "$SHELL" != *zsh ]]; then
    if ask "Set zsh as default shell?"; then
        chsh -s "$(which zsh)" "$TARGET_USER"
        echo "[+] Default shell set to zsh. Relog required."
    fi
fi

echo "[✅] Bootstrap complete! Use 'term' to launch your terminal + tmux."
