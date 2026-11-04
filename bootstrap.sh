#!/usr/bin/env bash
# Install Ansible and run the playbook against this machine.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

case "$OSTYPE" in
  linux-gnu*)
    if ! command -v pacman >/dev/null; then
      echo "Unsupported Linux distribution (Arch only)." >&2; exit 1
    fi
    sudo pacman -S --needed --noconfirm ansible git
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
