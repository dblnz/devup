#!/usr/bin/env bash
# Install Ansible and run the playbook against this machine.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

case "$OSTYPE" in
  linux-gnu*)
    if command -v pacman >/dev/null; then
      sudo pacman -S --needed --noconfirm ansible git
    elif [[ -r /etc/fedora-release ]]; then
      sudo dnf install -y ansible-core git python3-libdnf5 python3-libselinux
    elif [[ -r /etc/os-release ]] && (. /etc/os-release; [[ "${ID:-}" == ubuntu ]]); then
      . /etc/os-release
      if ! dpkg --compare-versions "${VERSION_ID:-0}" ge 24.04; then
        echo "Ubuntu 24.04 or newer is required." >&2; exit 1
      fi
      sudo apt-get update
      sudo apt-get install -y ansible-core git python3-apt ca-certificates
    else
      echo "Unsupported Linux distribution (Arch, Fedora and Ubuntu 24.04+ only)." >&2; exit 1
    fi
    ;;
  darwin*)
    if ! command -v brew >/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    brew install ansible git
    ;;
  *)
    echo "Unsupported OS: $OSTYPE" >&2; exit 1 ;;
esac

ansible-galaxy collection install -r requirements.yml
exec ansible-playbook site.yml --ask-become-pass "$@"
