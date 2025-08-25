#!/usr/bin/env bash
# term.sh — launches terminal + tmux
set -euo pipefail

TARGET_USER=${TARGET_USER:-goldsteal}
USER_HOME=$(eval echo "~$TARGET_USER")

SESSION_TYPE=${XDG_SESSION_TYPE:-}

install_if_missing() {
    local pkg=$1
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "[*] Installing $pkg..."
        sudo brl fetch "$pkg" || sudo pacman -S --noconfirm "$pkg" || sudo apt install -y "$pkg"
    fi
}

if [[ "$1" == "--install" ]]; then
    echo "[*] Installing terminal launcher..."
    # just ensure binaries installed
    if [[ "$SESSION_TYPE" == "wayland" ]]; then
        install_if_missing foot
    else
        install_if_missing alacritty
    fi
    install_if_missing tmux
    echo "[+] Terminal launcher ready. Run './term.sh' to start."
    exit 0
fi

# Run terminal + tmux
if [[ "$SESSION_TYPE" == "wayland" ]]; then
    sudo -u "$TARGET_USER" foot -e tmux
else
    sudo -u "$TARGET_USER" alacritty -e tmux
fi
