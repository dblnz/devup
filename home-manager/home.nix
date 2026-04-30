{ config, pkgs, lib, ... }:

{
  # Import all module configurations
  imports = [
    ./modules/bash.nix
    ./modules/cli-tools.nix
    ./modules/common-packages.nix
    ./modules/neovim.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Basic home configuration
  home = {
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "26.05";

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      # Help Rust/clang-sys/bindgen find Nix's libclang instead of system paths
      LIBCLANG_PATH = "${lib.getLib pkgs.llvmPackages_18.libclang}/lib";
    };

    # Session path additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/bin"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable XDG base directories
  xdg.enable = true;
}
