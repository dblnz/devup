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

## Git commit signing (per machine)

Global Git config is managed by Home Manager, but the **signing key is not** — each machine picks its own SSH key via a local file that Git includes.

1. Copy the example and edit the key path for this machine:

```sh
mkdir -p ~/.config/git
cp ~/devup/home-manager/signing.local.example ~/.config/git/signing.local
$EDITOR ~/.config/git/signing.local
```

Set `signingkey` to your public key (for example `~/.ssh/id_rsa.pub`).

2. Create `~/.ssh/allowed_signers` (required for SSH signing). Use the same email as in `home-manager/modules/git.nix`:

```sh
echo '<email> namespaces="git" '"$(cat ~/.ssh/YOUR_KEY.pub)" > ~/.ssh/allowed_signers
chmod 644 ~/.ssh/allowed_signers
```

3. Apply Home Manager if you have not since enabling signing:

```sh
home-manager switch --flake ~/devup#linux
```

4. Add the same `.pub` key on GitHub under **Settings → SSH and GPG keys → Signing keys**, then verify:

```sh
git config --global user.signingkey
git commit --allow-empty -m "test signing"
git log -1 --show-signature
```

`~/.config/git/signing.local` is not in this repo — do not commit it. Other hosts can use a different key without changing the flake.

## Roll back

If something goes wrong, roll back to the previous Home Manager generation:

```sh
home-manager switch --rollback
```
