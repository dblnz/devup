{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;

    # Use zsh as default shell
    shell = "${pkgs.zsh}/bin/zsh";

    # Terminal settings
    terminal = "xterm-256color";

    newSession = true;
    # Enable mouse support
    mouse = true;

    # Use vi mode
    keyMode = "vi";

    # Start window and pane numbering at 1
    baseIndex = 1;

    escapeTime = 0;
    secureSocket = false;
    clock24 = true;

    # Renumber windows when one is closed
    #renumberWindows = true;

    # Increase scrollback buffer size
    historyLimit = 50000;

    # Set prefix key (default is C-b)
    # prefix = "C-a";  # Uncomment to use C-a instead of C-b

    # Additional configuration
    extraConfig = ''
      # Set PATH for tmux sessions
      #set-environment -g PATH "$PATH:/usr/local/bin"

      # Better split commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Vim-like pane resizing
      bind C-h resize-pane -L 5
      bind C-j resize-pane -D 2
      bind C-k resize-pane -U 2
      bind C-l resize-pane -R 5

      # Pane resizing to max and back to previous
      bind H run-shell 'tmux set -w @saved_layout "$(tmux display-message -p "#{window_layout}")"; tmux resize-pane -y 999'
      bind W run-shell 'tmux set -w @saved_layout "$(tmux display-message -p "#{window_layout}")"; tmux resize-pane -x 999'
      bind R run-shell 'tmux select-layout "$(tmux show -wv @saved_layout)"'

      # Cycle through panes
      bind o select-pane -t :.+
      bind i select-pane -t :.-
    '';

    # Plugins
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.power-theme
    ];
  };
}
