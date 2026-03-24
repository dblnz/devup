{
  description = "dblnz's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config = {
      url = "github:dblnz/nvim-dotfiles";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Helper function to create home-manager configuration
      mkHome = { system, username, homeDirectory, extraModules ? [] }:
        let
          # Share the same pkgs for both module scope and inline usage
          pkgsForHome = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ ];
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsForHome;

          modules = [
            ./home-manager/home.nix
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "26.05";
              };
              _module.args = {
                nvim-config = inputs.nvim-config;
              };
            }
          ] ++ extraModules;
        };
    in
    {
      # Home Manager configurations for different systems
      homeConfigurations = {
        # Linux configuration
        "linux" = mkHome {
          system = "x86_64-linux";
          username = "dblnz";
          homeDirectory = "/home/dblnz";
          extraModules = [ ./home-manager/linux.nix ];
        };

        # macOS configuration
        "darwin" = mkHome {
          system = "aarch64-darwin";  # Apple Silicon
          username = "dblnz";
          homeDirectory = "/Users/dblnz";
          extraModules = [ ./home-manager/darwin.nix ];
        };

        # macOS Intel configuration
        "darwin-intel" = mkHome {
          system = "x86_64-darwin";  # Intel Mac
          username = "dblnz";
          homeDirectory = "/Users/dblnz";
          extraModules = [ ./home-manager/darwin.nix ];
        };
      };

      # Templates for project-specific development environments
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust development environment";
        };

        c = {
          path = ./templates/c;
          description = "C/C++ development environment";
        };

        node = {
          path = ./templates/node;
          description = "Node.js development environment";
        };

        python = {
          path = ./templates/python;
          description = "Python development environment";
        };

        go = {
          path = ./templates/go;
          description = "Go development environment";
        };
      };

      # Development shells
      devShells = lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          # Default shell
          default = pkgs.mkShell {
            name = "dev-shell";
            packages = with pkgs; [
              git
              nodejs_22
            ];
          };
        }
      );
    };
}
