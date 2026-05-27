{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # Shell aliases
    shellAliases = {
      cat = "bat";
      grep = "grep --color";
      egrep = "egrep --color";
      tree = "tree -C";
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Git shortcuts (in addition to git aliases)
      g = "git";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";

      # Nix shortcuts
      hms = "home-manager switch --flake .";
      hmb = "home-manager build --flake .";
    };

    # Additional shell options
    initContent = ''
      # FZF integration (if installed)
      if command -v fzf >/dev/null; then
        # Keybindings
        [[ -r "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]] && source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
        [[ -r "${pkgs.fzf}/share/fzf/completion.zsh" ]] && source "${pkgs.fzf}/share/fzf/completion.zsh"
      fi

      # Bind Ctrl-Space to accept autosuggestion
      bindkey '^ ' autosuggest-accept

      # Better history search
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down

      # Edit command line in editor
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^X^E" edit-command-line

      # Customize prompt colors
      autoload -U colors && colors
    '';

    # Oh-My-Zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
        "rust"
        "golang"
        "python"
        "tmux"
        "colored-man-pages"
        "command-not-found"
        "history-substring-search"
      ];
      theme = "robbyrussell";  # Can be customized
    };

    # Additional plugins via home-manager
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
          sha256 = "gvZp8P3quOtcy1Xtt1LAW1cfZ/zCtnAmnWqcwrKel6w=";
        };
      }
    ];
  };

  # Install fzf for fuzzy finding
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
