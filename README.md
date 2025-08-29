Bootstrap Scripts

This repo contains modular scripts to bootstrap a Bedrock Linux system with a minimal but sane setup:

Cross-strata package setup (Arch/Debian/Fedora, optional)

Terminal launcher (term.sh) → runs alacritty (X11/i3) or foot (Wayland/sway) with tmux

Color palette for Alacritty + tmux

Window manager setup (i3 or sway, with vim-like keybindings)

SSH server setup with sensible defaults

Zsh shell setup

All scripts stay inside this repo folder → no $HOME/bin, no /usr/local/bin, no symlinks.

🚀 Quickstart

On a fresh install:
# 1. Clone repo
git clone https://github.com/<your-username>/bootstrap-scripts.git
cd bootstrap-scripts

# 2. Make scripts executable
chmod +x *.sh

# 3. Run bootstrap
./bootstrap.sh

📂 Script Structure

🖥️ Terminal

⚙️ Config Scripts

colors.sh → applies unified color scheme for Alacritty + tmux

term.sh → terminal + tmux launcher

wm-setup.sh → configures i3 or sway with vim-like keybindings

ssh-setup.sh → sets up OpenSSH server, enables login for $TARGET_USER

bootstrap.sh → orchestrator; runs the above in safe sequence

🔑Default User

All scripts assume the user is called:
goldsteal

For other users run with:
TARGET_USER=yourname ./bootstrap.sh


🔒 Security Note

By default:

Root login via SSH is disabled

Password login is enabled (for initial setup)

You should later add an SSH key and set PasswordAuthentication no in /etc/ssh/sshd_config

