#!/usr/bin/env bash
# bootstrap.sh — Modular Bedrock Linux bootstrap with strata, tools, terminal, colors, and SSH
set -euo pipefail

ask() {
    read -rp "$1 [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

install_if_missing() {
    local pkg=$1
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "[*] Installing $pkg..."
        brl fetch "$pkg" || sudo pacman -S --noconfirm "$pkg" || sudo apt install -y "$pkg"
    else
        echo "[+] $pkg already installed."
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
        echo "[!] Missing $script (expected for $desc)."
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
WAYLAND_PKGS=(foot)
X11_PKGS=(alacritty)
AUR_PKGS=(yay)

for pkg in "${COMMON_PKGS[@]}"; do
    install_if_missing "$pkg"
done

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
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
    # Check if Arch stratum exists
    if brl which -s pacman >/dev/null 2>&1; then
        echo "[*] Arch stratum detected."

        # Prompt for yay installation
        if ask "Do you want to install yay (AUR helper) in Arch stratum?"; then
            echo "[*] Installing base-devel and git in Arch stratum..."
            brl sh -c 'sudo pacman -Sy --noconfirm --needed base-devel git'

            echo "[*] Cloning and building yay..."
            brl sh -c '
                cd /tmp &&
                rm -rf yay &&
                git clone https://aur.archlinux.org/yay.git &&
                cd yay &&
                makepkg -si --noconfirm
            '
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
# Step 4: Apply configs (colors + term launcher)
# -----------------------
safe_run_config ~/bin/unified-colors.sh "color palette"
safe_run_config "~/bin/term.sh --install" "term launcher"

# -----------------------
# Step 5: SSH setup
# -----------------------
echo "[*] Running SSH setup..."
sudo ~/bin/ssh-setup.sh

# -----------------------
# Step 6: Set zsh as default shell (optional)
# -----------------------
if [[ "$SHELL" != *zsh ]]; then
    if ask "Set zsh as your default shell?"; then
        chsh -s "$(which zsh)"
        echo "[+] Default shell set to zsh. Relog required."
    fi
fi

# -----------------------
# Finish
# -----------------------
echo "[✅] Bootstrap complete!"
echo "    • Restart or log out to apply shell changes."
echo "    • Use 'term' to launch your terminal + tmux."
echo "    • SSH configured for 'goldsteal'. Remember to harden root login if enabled."
