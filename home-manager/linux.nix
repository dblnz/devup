{ config, pkgs, lib, ... }:

{
  # Linux-specific configuration
  
  home.packages = with pkgs; [
    # Linux-specific tools
  ];

  # Linux-specific environment variables
  home.sessionVariables = {
    # Add Linux-specific vars here if needed
  };

  # SSH agent as a systemd user service
  services.ssh-agent.enable = true;
}
