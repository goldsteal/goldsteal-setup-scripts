#!/usr/bin/env bash
set -euo pipefail

echo "[*] Setting up unified terminal color palette..."

# --- Define palette ---
BLACK="#1E1E1E"
RED="#E53935"
GREEN="#4CAF50"
YELLOW="#FFEB3B"
BLUE="#1E88E5"
MAGENTA="#9C27B0"
CYAN="#00ACC1"
WHITE="#E0E0E0"

# Detect Wayland vs X11
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    echo "[*] Wayland detected → configuring Foot"
    mkdir -p ~/.config/foot
    cat > ~/.config/foot/foot.ini <<EOF
[colors]
background=$BLACK
foreground=$WHITE

regular0=$BLACK
regular1=$RED
regular2=$GREEN
regular3=$YELLOW
regular4=$BLUE
regular5=$MAGENTA
regular6=$CYAN
regular7=$WHITE

bright0=#555555
bright1=$RED
bright2=$GREEN
bright3=$YELLOW
bright4=$BLUE
bright5=$MAGENTA
bright6=$CYAN
bright7=#FAFAFA
EOF
    echo "[+] Foot palette written to ~/.config/foot/foot.ini"

else
    echo "[*] X11 detected (or fallback) → configuring Alacritty"
    mkdir -p ~/.config/alacritty
    cat > ~/.config/alacritty/alacritty.toml <<EOF
[colors.primary]
background = "$BLACK"
foreground = "$WHITE"

[colors.normal]
black   = "$BLACK"
red     = "$RED"
green   = "$GREEN"
yellow  = "$YELLOW"
blue    = "$BLUE"
magenta = "$MAGENTA"
cyan    = "$CYAN"
white   = "$WHITE"

[colors.bright]
black   = "#555555"
red     = "$RED"
green   = "$GREEN"
yellow  = "$YELLOW"
blue    = "$BLUE"
magenta = "$MAGENTA"
cyan    = "$CYAN"
white   = "#FAFAFA"
EOF
    echo "[+] Alacritty palette written to ~/.config/alacritty/alacritty.toml"
fi

# --- tmux config ---
cat > ~/.tmux.conf <<EOF
set -g default-terminal "screen-256color"

# Status bar colors
set -g status-bg $BLUE
set -g status-fg $WHITE

# Window title colors
setw -g window-status-current-style fg=$YELLOW,bg=$BLUE,bold
setw -g window-status-style fg=$WHITE,bg=$BLACK

# Pane border colors
set -g pane-border-style fg=$CYAN
set -g pane-active-border-style fg=$GREEN
EOF
echo "[+] tmux palette written to ~/.tmux.conf"

# --- Zsh (Oh My Zsh prompt colors) ---
if ! grep -q "PROMPT='%{$fg" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc <<'EOF'

# --- Custom Prompt Colors ---
autoload -U colors && colors
PROMPT='%{$fg[cyan]%}%n@%m %{$fg[blue]%}%~ %{$fg[yellow]%}$ %{$reset_color%}'
EOF
    echo "[+] Zsh palette updated in ~/.zshrc"
else
    echo "[*] Zsh prompt already configured, skipping..."
fi

echo "[*] Done. Restart your terminal or reload configs:"
echo "   - tmux: tmux source-file ~/.tmux.conf"
echo "   - zsh : source ~/.zshrc"
