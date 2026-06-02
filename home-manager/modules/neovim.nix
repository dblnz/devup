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

  # Sync ~/.config/nvim-dotfiles from the flake input on every activation,
  # then symlink ~/.config/nvim → the mutable local copy so edits are live.
  # NOTE: This overwrites local changes in nvim-dotfiles with the flake input.
  home.activation.seedNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_SRC="${config.home.homeDirectory}/.config/nvim-dotfiles"
    NVIM_LINK="${config.home.homeDirectory}/.config/nvim"
    run rm -rf "$NVIM_SRC"
    run cp -r "${nvim-config}" "$NVIM_SRC"
    run chmod -R u+w "$NVIM_SRC"
    if [ ! -L "$NVIM_LINK" ] || [ "$(readlink "$NVIM_LINK")" != "$NVIM_SRC" ]; then
      run rm -rf "$NVIM_LINK"
      run ln -s "$NVIM_SRC" "$NVIM_LINK"
    fi
  '';
}
