#!/usr/bin/env bash
# bootstrap.sh — Full modular Bedrock Linux bootstrap
set -euo pipefail

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
# Step 2: Configure strata
# -----------------------
if ask "Do you want to configure recommended strata (Arch, Debian, Fedora)?"; then
    sudo brl fetch arch
    sudo brl fetch debian
    sudo brl fetch fedora
fi

# -----------------------
# Step 3: Install common tools
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
# Step 3b: Install yay (optional, Arch-only)
# -----------------------
install_yay() {
    if brl which -s pacman >/dev/null 2>&1; then
        echo "[*] Arch stratum detected."
        if ask "Do you want to install yay (AUR helper) in Arch stratum?"; then
            sudo brl sh -c 'pacman -Sy --noconfirm --needed base-devel git'
            sudo brl sh -c 'cd /tmp && rm -rf yay && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm'
            echo "[+] yay installed in Arch stratum."
        else
            echo "[!] Skipped yay installation."
        fi
    else
        echo "[!] Arch stratum not detected; skipping yay."
    fi
}
install_yay

# -----------------------
# Step 4: Apply configs (colors + terminal launcher)
# -----------------------
safe_run_config "$USER_HOME/bin/colors.sh" "color palette"
safe_run_config "$USER_HOME/bin/term.sh --install" "term launcher"

# -----------------------
# Step 4b: WM & keybindings setup
# -----------------------
safe_run_config "$USER_HOME/bin/wm-setup.sh" "Window Manager (i3/sway) + vim-like keybindings"

# -----------------------
# Step 5: SSH setup
# -----------------------
echo "[*] Running SSH setup..."
sudo "$USER_HOME/bin/ssh-setup.sh"

# -----------------------
# Step 6: Set zsh as default shell (optional)
# -----------------------
if [[ "$SHELL" != *zsh ]]; then
    if ask "Set zsh as your default shell?"; then
        chsh -s "$(which zsh)" "$TARGET_USER"
        echo "[+] Default shell set to zsh. Relog required."
    fi
fi

# -----------------------
# Finish
# -----------------------
echo "[✅] Bootstrap complete!"
echo "    • Restart or log out to apply shell changes."
echo "    • Use 'term' to launch your terminal + tmux."
echo "    • SSH configured for '$TARGET_USER'."
echo "    • WM installed with vim-like keybindings; terminal auto-launch configured."
