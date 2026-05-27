{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # SSH commit signing (shared). Key path and allowed_signers are per-machine —
    # see ~/.config/git/signing.local (copy from signing.local.example).
    signing = {
      format = "ssh";
      signByDefault = true;
    };

    includes = [
      {
        path = "${config.home.homeDirectory}/.config/git/signing.local";
      }
    ];

    settings = {
      user = {
        name = "Doru Blânzeanu";
        email = "dblnz@pm.me";
      };

      credential.helper = "store";

      color.ui = "auto";

      core = {
        editor = "nvim";
      };

      diff = {
        tool = "vimdiff";
      };

      difftool = {
        prompt = false;
      };

      pager = {
        log = false;
      };

      # Aliases
      alias = {
        # Branch management
        b = "branch -vv";
        co = "checkout";

        # Commit
        ci = "commit --signoff";

        # Diff and status
        d = "diff";
        st = "status";

        # Log aliases
        l = "log --decorate --graph --oneline";

        dag = "log --graph --format='format:%C(yellow)%h%C(reset) %C(blue)\"%an\" <%ae>%C(reset) %C(magenta)%cr%C(reset)%C(auto)%d%C(reset)%n%s' --date-order";
        ld = "log --decorate --graph --oneline --pretty=format:'%C(bold red)%h%Creset %Cgreen(%cr) %C(bold blue)<%aN>%Creset %s %C(yellow)%d%Creset' --abbrev-commit";
        lg = "log --graph --pretty=format:'commit: %C(bold red)%h%Creset %C(red)<%H>%Creset %C(bold magenta)%d %Creset%ndate: %C(bold yellow)%cd %Creset%C(yellow)%cr%Creset%nauthor: %C(bold blue)%an%Creset %C(blue)<%ae>%Creset%n%C(cyan)%s%n%Creset'";
        me = "!git lg --author='Doru Blânzeanu'";
      };
    };

    # Git ignore patterns
    ignores = [
      "*~"
      "*.swp"
      "*.swo"
      ".DS_Store"
      "Thumbs.db"
      ".idea/"
      ".vscode/"
      "*.log"
      ".direnv/"
      ".envrc"
    ];
  };

  # Delta for better diffs (separate program config)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      line-numbers = true;
      side-by-side = true;
    };
  };
}
