#!/usr/bin/env bash
# ssh-setup.sh — install & configure OpenSSH and a sane default sshd setup.
# Idempotent: safe to re-run.
set -euo pipefail

# -----------------------
# Helper functions
# -----------------------
require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root (e.g., sudo $0)"; exit 1
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

install_openssh() {
  echo "[*] Installing OpenSSH server (if missing)..."
  if have pacman;        then pacman -Sy --noconfirm --needed openssh
  elif have apt;         then apt update -y && apt install -y openssh-server
  elif have dnf;         then dnf install -y openssh-server
  elif have zypper;      then zypper -n install openssh
  elif have xbps-install;then xbps-install -y openssh
  else
    echo "[!] No known package manager found. Install OpenSSH manually."; exit 1
  fi
}

ensure_user() {
  local user="$1"
  local def_shell="/usr/bin/zsh"
  [[ -x "$def_shell" ]] || def_shell="/bin/bash"

  if id -u "$user" >/dev/null 2>&1; then
    echo "[+] User '$user' already exists."
  else
    echo "[*] Creating user '$user' with home and shell $def_shell ..."
    useradd -m -s "$def_shell" "$user"
  fi

  # Ensure .ssh directory with safe perms
  local home
  home="$(getent passwd "$user" | cut -d: -f6)"
  mkdir -p "$home/.ssh"
  chmod 700 "$home/.ssh"
  touch "$home/.ssh/authorized_keys"
  chmod 600 "$home/.ssh/authorized_keys"
  chown -R "$user":"$user" "$home/.ssh"

  # Prompt to set (or reset) password
  echo "[*] Set a password for '$user' (required for password login):"
  passwd "$user"
}

write_sshd_dropin() {
  local d="/etc/ssh/sshd_config.d"
  local f="$d/99-sane.conf"

  # Ask user whether to allow root login
  echo
  read -rp "[?] Allow SSH login as root? (y/N): " allow_root
  allow_root=${allow_root,,}   # lowercase

  local root_line
  if [[ "$allow_root" == "y" ]]; then
    root_line="PermitRootLogin yes    # NOTE: INSECURE — remove/change to 'no' after setup"
  else
    root_line="PermitRootLogin no"
  fi

  if [[ -d "$d" ]]; then
    echo "[*] Writing sshd drop-in: $f"
    install -m 644 /dev/null "$f"
    cat > "$f" <<EOF
# Managed by ssh-setup.sh — sane defaults
# Login policy
$root_line
PubkeyAuthentication yes
PasswordAuthentication yes     # set to 'no' after you add keys
KbdInteractiveAuthentication no
UsePAM yes
MaxAuthTries 3
LoginGraceTime 30s
# Session behavior
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
# Limit to your user
AllowUsers goldsteal
EOF
  else
    # Fallback: edit main config in-place (backup first)
    local main="/etc/ssh/sshd_config"
    echo "[*] Drop-in dir not found; updating $main (backup kept)."
    cp -a "$main" "${main}.bak.$(date +%s)" || true

    set_opt() {
      local key="$1" val="$2"
      if grep -Ei "^\s*${key}\b" "$main" >/dev/null 2>&1; then
        sed -ri "s|^\s*(${key})\s+.*$|\1 ${val}|I" "$main"
      else
        printf "%s %s\n" "$key" "$val" >> "$main"
      fi
    }

    set_opt PermitRootLogin "${root_line#PermitRootLogin }"
    set_opt PubkeyAuthentication yes
    set_opt PasswordAuthentication yes
    set_opt KbdInteractiveAuthentication no
    set_opt UsePAM yes
    set_opt MaxAuthTries 3
    set_opt LoginGraceTime 30s
    set_opt X11Forwarding no
    set_opt AllowAgentForwarding yes
    set_opt AllowTcpForwarding yes
    set_opt ClientAliveInterval 300
    set_opt ClientAliveCountMax 2
    if grep -Ei "^\s*AllowUsers\b" "$main" >/dev/null 2>&1; then
      sed -ri 's|^\s*(AllowUsers)\s+.*$|\1 goldsteal|I' "$main"
    else
      echo "AllowUsers goldsteal" >> "$main"
    fi
  fi
}

enable_service() {
  echo "[*] Enabling and starting sshd..."
  if have systemctl; then
    systemctl enable --now sshd 2>/dev/null || systemctl enable --now ssh
    systemctl --no-pager status sshd ssh 2>/dev/null || true
  elif have rc-service; then
    rc-update add sshd default || rc-update add ssh default || true
    rc-service sshd restart   || rc-service ssh restart   || true
  elif have sv; then
    sv up sshd 2>/dev/null || sv up ssh 2>/dev/null || true
  else
    echo "[!] Could not auto-enable service; start sshd manually."
  fi
}

open_firewall() {
  echo "[*] Adjusting firewall (if present)..."
  if have ufw; then
    ufw allow OpenSSH || ufw allow 22/tcp || true
  fi
  if have firewall-cmd; then
    firewall-cmd --permanent --add-service=ssh || true
    firewall-cmd --reload || true
  fi
}

# -----------------------
# Main
# -----------------------
main() {
  require_root
  install_openssh
  ensure_user "goldsteal"
  write_sshd_dropin
  enable_service
  open_firewall

  echo
  echo "[✅] SSH server configured."
  echo "    • User: goldsteal"
  echo "    • Password login: ENABLED (consider disabling after adding keys)."
  echo "    • Add your key:   ssh-copy-id goldsteal@<host-or-ip>"
  echo "    • Test:           ssh -v goldsteal@<host-or-ip>"

  # Reminder for root login
  if [[ "$allow_root" == "y" ]]; then
    echo
    echo "[⚠️] WARNING: Root login over SSH is ENABLED!"
    echo "        For hardening, remove or set 'PermitRootLogin no' in your sshd config after initial setup."
  fi
}

main "$@"
