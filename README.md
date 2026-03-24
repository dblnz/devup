# Development Setup (Nix + Home Manager)

Minimal instructions to get started, use templates, manage Home Manager, and roll back if needed.

## Quick start

If you have `nix` installed:
```sh
nix run home-manager/master -- switch --flake github:dblnz/dev-env#dblnz@linux -b backup
```

If not you can use:
```sh
git clone <repo-url> ~/dev-env
cd ~/dev-env
./bootstrap.sh
```

The bootstrap script installs Nix if needed, enables flakes, and activates the appropriate Home Manager profile for your OS.

## Use project templates

From a new or empty project directory:

```sh
# If cloned locally
nix flake init -t ~/dev-env#rust

# Or directly from GitHub
nix flake init -t github:dblnz/dev-env#rust

# Enter the dev environment
nix develop
```

Available templates: rust, c, node, python, go

## Manage with Home Manager

Apply changes again later using the same profile that bootstrap selected:

```sh
cd ~/dev-env
# Linux
home-manager switch --flake .#dblnz@linux
# macOS (Apple Silicon)
home-manager switch --flake .#dblnz@darwin
# macOS (Intel)
home-manager switch --flake .#dblnz@darwin-intel
```

Build without switching (evaluation/build only):

```sh
home-manager build --flake .#dblnz@linux   # or the matching profile for your OS
```

## Roll back

If something goes wrong, roll back to the previous Home Manager generation:

```sh
home-manager switch --rollback
```
