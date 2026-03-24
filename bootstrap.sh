#!/usr/bin/env bash
# Bootstrap script for setting up Nix and Home Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Globals set during execution
OS=""
PROFILE=""
SCRIPT_DIR=""

echo "Bootstrapping Nix development environment..."

# -----------------------------
# Functions
# -----------------------------

# Detect operating system and choose the appropriate Home Manager profile
detect_os_and_profile() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    PROFILE="linux"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
    if [[ $(uname -m) == "arm64" ]]; then
      PROFILE="darwin"
    else
      PROFILE="darwin-intel"
    fi
  else
    echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
    exit 1
  fi

  echo -e "${GREEN}Detected OS: $OS${NC}"
  echo -e "${GREEN}Using profile: $PROFILE${NC}"
}

# Ensure Nix is installed; if not, install it and source the environment
install_nix_if_missing() {
  if ! command -v nix &>/dev/null; then
    echo -e "${YELLOW}Nix is not installed. Installing Nix...${NC}"

    if [[ "$OS" == "darwin" ]]; then
      # macOS installation
      sh <(curl -L https://nixos.org/nix/install)
    else
      # Linux installation (multi-user)
      sh <(curl -L https://nixos.org/nix/install) --daemon
    fi

    # Source Nix (daemon profile if present)
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
  else
    echo -e "${GREEN}Nix is already installed${NC}"
  fi
}

# Enable Nix flakes feature flag in user configuration
enable_nix_flakes() {
  echo -e "${YELLOW}Enabling Nix flakes...${NC}"
  mkdir -p ~/.config/nix
  if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
    echo -e "${GREEN}Flakes enabled${NC}"
  else
    echo -e "${GREEN}Flakes already enabled${NC}"
  fi
}

# Determine the absolute directory of this script
determine_script_dir() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Build and activate the Home Manager configuration for the selected profile
activate_home_manager() {
  echo -e "${YELLOW}Building and activating Home Manager configuration...${NC}"
  cd "$SCRIPT_DIR"
  nix run home-manager/master -- switch --flake ".#$PROFILE" -b backup
}

# Final helpful instructions
print_next_steps() {
  echo -e "${GREEN}✨ Bootstrap complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Restart your shell or run: source ~/.nix-profile/etc/profile.d/hm-session-vars.sh"
  echo "2. To apply future changes: home-manager switch --flake ."
  echo "3. To create a project: nix flake init -t .#rust (or c, node, python, go)"
  echo ""
  echo "Read NIX_README.md for more information."
}

# Orchestrate the bootstrap flow
main() {
  detect_os_and_profile
  install_nix_if_missing
  enable_nix_flakes
  determine_script_dir
  activate_home_manager
  print_next_steps
}

main "$@"
