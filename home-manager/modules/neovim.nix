{ config, pkgs, lib, nvim-config, neovim-src, ... }:

let
  # Build neovim from source using the pinned tag
  neovim-custom = (pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
    version = "0.12.2";
    src = neovim-src;
  }));
in
{
  programs.neovim = {
    enable = true;
    package = neovim-custom;

    # Use neovim as the default editor
    defaultEditor = true;

    # Enable vi/vim aliases
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Enable common remote providers for plugin ecosystems
    withNodeJs = true;
    withPython3 = true;

    # NOTE: Do NOT set initLua here. The entire ~/.config/nvim directory is
    # symlinked to the mutable nvim-dotfiles clone via xdg.configFile below,
    # and a Nix-managed init.lua would conflict with that symlink.

    # Neovim plugins managed by Nix (optional)
    # The plugins are managed using lazy.nvim
    plugins = with pkgs.vimPlugins; [
      # Example: Core plugins
      # plenary-nvim
    ];

    # Additional packages available to Neovim
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil  # Nix LSP

      # Formatters
      stylua
      nixpkgs-fmt

      # Other tools
      ripgrep
      fd
      tree-sitter
    ];
  };

  # Seed ~/.config/nvim-dotfiles from the flake input on first activation.
  # Copies from the Nix store so the result is a mutable, editable directory.
  # Subsequent activations leave the directory untouched.
  home.activation.seedNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_SRC="${config.home.homeDirectory}/.config/nvim-dotfiles"
    if [ ! -d "$NVIM_SRC" ]; then
      run cp -r "${nvim-config}" "$NVIM_SRC"
      run chmod -R u+w "$NVIM_SRC"
    fi
  '';

  # Symlink ~/.config/nvim → the mutable local copy so edits are live
  # without needing a home-manager switch round-trip.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim-dotfiles";
}
