{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;

    enableCompletion = true;

    # Bash history configuration
    historySize = 10000;
    historyFileSize = 20000;
    historyControl = [ "ignoredups" "ignorespace" ];

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

      # Git shortcuts
      g = "git";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    };

    # Custom bash configuration
    bashrcExtra = ''
      # Custom PS1 prompt with colors
      __PS1_BLUE="\[$(tput setaf 4)\]"
      __PS1_CYAN="\[$(tput setaf 6)\]"
      __PS1_GREEN="\[$(tput setaf 2)\]"
      __PS1_RED="\[$(tput setaf 1)\]"
      __PS1_YELLOW="\[$(tput setaf 3)\]"
      __PS1_CLEAR="\[$(tput sgr0)\]"
      export PS1="''${__PS1_RED}[\A]''${__PS1_GREEN} \u@\h:''${__PS1_CLEAR}[''${__PS1_CYAN}\W''${__PS1_CLEAR}]# "

      # Better command history
      shopt -s histappend
      shopt -s cmdhist

      # Update window size after each command
      shopt -s checkwinsize

      # Better directory navigation
      shopt -s autocd 2>/dev/null
      shopt -s dirspell 2>/dev/null
      shopt -s cdspell 2>/dev/null
    '';

    # Profile extra (for login shells)
    profileExtra = ''
      # Ensure Nix environment is available (survives system/WSL resets)
      if [ -z "$NIX_PROFILES" ]; then
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
          . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        fi
      fi
    '';
  };
}
