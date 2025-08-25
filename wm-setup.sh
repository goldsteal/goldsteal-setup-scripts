#!/usr/bin/env bash
# wm-setup.sh — Configure i3 (X11) or sway (Wayland) with vim-like keybindings and auto-terminal
set -euo pipefail

TARGET_USER=${TARGET_USER:-goldsteal}
USER_HOME=$(eval echo "~$TARGET_USER")
WM_CONFIG_DIR="$USER_HOME/.config"
SESSION_TYPE=${XDG_SESSION_TYPE:-}

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

echo "[*] Detected session: $SESSION_TYPE"

# Paths for override configs
WM_OVERRIDE_I3="$WM_CONFIG_DIR/i3/config.override"
WM_OVERRIDE_SWAY="$WM_CONFIG_DIR/sway/config.override"

if [[ "$SESSION_TYPE" == "wayland" ]]; then
    echo "[*] Installing sway + foot..."
    install_if_missing sway
    install_if_missing foot

    mkdir -p "$WM_CONFIG_DIR/sway"
    if [[ -f "$WM_OVERRIDE_SWAY" ]]; then
        cp "$WM_OVERRIDE_SWAY" "$WM_CONFIG_DIR/sway/config"
        echo "[+] Using sway override config."
    elif [[ ! -f "$WM_CONFIG_DIR/sway/config" ]]; then
        cp /etc/sway/config "$WM_CONFIG_DIR/sway/config"
        cat >> "$WM_CONFIG_DIR/sway/config" <<'EOF'
# Vim-like movement
bindsym h focus left
bindsym j focus down
bindsym k focus up
bindsym l focus right

# Terminal
bindsym Return exec foot
EOF
        echo "[+] Default sway config with vim-like bindings applied."
    else
        echo "[+] Existing sway config found; skipping."
    fi

elif [[ "$SESSION_TYPE" == "x11" ]]; then
    echo "[*] Installing i3 + alacritty..."
    install_if_missing i3
    install_if_missing alacritty

    mkdir -p "$WM_CONFIG_DIR/i3"
    if [[ -f "$WM_OVERRIDE_I3" ]]; then
        cp "$WM_OVERRIDE_I3" "$WM_CONFIG_DIR/i3/config"
        echo "[+] Using i3 override config."
    elif [[ ! -f "$WM_CONFIG_DIR/i3/config" ]]; then
        cp /etc/i3/config "$WM_CONFIG_DIR/i3/config"
        cat >> "$WM_CONFIG_DIR/i3/config" <<'EOF'
# Vim-like movement
bindsym h focus left
bindsym j focus down
bindsym k focus up
bindsym l focus right

# Terminal
bindsym Return exec alacritty
EOF
        echo "[+] Default i3 config with vim-like bindings applied."
    else
        echo "[+] Existing i3 config found; skipping."
    fi

else
    echo "[!] Could not detect X11 or Wayland session. Start session manually."
fi
