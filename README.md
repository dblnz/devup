# Development Setup (Nix + Home Manager)

This is my personal development setup, it isn't much, but it helps me go through the day without dealing with IDEs.
Minimal instructions to get started, use templates, manage Home Manager, and roll back if needed.

> [!NOTE]
> This configuration uses `dblnz` as username.
> To modify this, you need to do a local checkout and modify the repository

## Quick start

If you have `nix` installed:
```sh
nix run home-manager/master -- switch --flake github:dblnz/devup#linux -b backup
```

If not, you can use:
```sh
git clone <repo-url> ~/devup
cd ~/devup
./bootstrap.sh
```

The bootstrap script installs Nix if needed, enables flakes, and activates the appropriate Home Manager profile for your OS.

## Use project templates

From a new or empty project directory:

```sh
# If cloned locally
nix flake init -t ~/devup#rust

# Or directly from GitHub
nix flake init -t github:dblnz/devup#rust

# Enter the dev environment
nix develop
```

Available templates: rust, c, node, python, go

## Manage with Home Manager

Apply changes again later using the same profile that bootstrap selected:

```sh
cd ~/devup
# Linux
home-manager switch --flake .#linux
# macOS (Apple Silicon)
home-manager switch --flake .#darwin
# macOS (Intel)
home-manager switch --flake .#darwin-intel
```

Build without switching (evaluation/build only):

```sh
home-manager build --flake .#linux   # or the matching profile for your OS
```

## Roll back

If something goes wrong, roll back to the previous Home Manager generation:

```sh
home-manager switch --rollback
```
