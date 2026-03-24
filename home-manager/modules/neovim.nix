{ config, pkgs, lib, nvim-config, ... }:

{
  programs.neovim = {
    enable = true;

    # Use neovim as the default editor
    defaultEditor = true;

    # Enable vi/vim aliases
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Enable common remote providers for plugin ecosystems
    withNodeJs = true;
    withPython3 = true;

    initLua = ''
      -- The lua config will be loaded from ~/.config/nvim
      -- This is just a placeholder for any additional Nix-managed config
    '';

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
