#!/usr/bin/env bash
# Save this as ~/bin/term and make it executable (chmod +x ~/bin/term)

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    exec foot tmux new-session -A -s main
else
    exec alacritty -e tmux new-session -A -s main
fi
