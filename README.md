# devup

Personal development setup as an Ansible playbook. Supports Arch Linux, Fedora and macOS (Homebrew).
It runs locally against the current user. Nothing is hardcoded to a username.

## Quick start

```sh
git clone <repo-url> ~/devup
cd ~/devup
./bootstrap.sh
```

`bootstrap.sh` installs Ansible (pacman, dnf or brew), installs the pinned collections and runs
`ansible-playbook site.yml --ask-become-pass`. Re-running it is the normal update flow.

Run only some roles with tags:

```sh
ansible-playbook site.yml --tags dotfiles,git
```

## Layout

| Path | Purpose |
|------|---------|
| `site.yml` | Entry point: runs the roles below |
| `roles/packages` | pacman / dnf / Homebrew packages (lists in `roles/packages/vars/<os_family>.yml`) |
| `roles/shell` | Sets zsh as the login shell |
| `roles/fonts` | Installs the JetBrainsMono Nerd Font (set it in your terminal) |
| `roles/dotfiles` | Symlinks `files/<tool>/*` into `$HOME` |
| `roles/git` | Renders `~/.config/git/config` from `git_user_name` / `git_user_email` |
| `roles/mise` | Installs global tools from `files/mise/config.toml` |
| `roles/neovim` | Clones the nvim config into `~/.config/nvim` (never overwrites local edits) |
| `roles/macspoof` | Opt-in MAC address spoofing systemd unit (Linux) |
| `templates/<lang>/mise.toml` | Starter per-project tool pins |

Per-machine overrides go in `host_vars/localhost.yml` (git-ignored):

```yaml
git_user_name: "Your Name"
git_user_email: you@example.com
macspoof_enabled: true
macspoof_interface: wlan0
```

## Fedora third-party sources

A few tools are not in the Fedora repos, so the playbook adds these sources:

| Tool | Source |
|------|--------|
| `mise` | Upstream RPM repo (`mise.jdx.dev/rpm`) |
| `starship`, `bottom` | COPR repos `atim/starship` and `atim/bottom` |
| `zsh-history-substring-search` | Git clone into `~/.local/share/zsh/plugins` |

## Git signing

SSH signing is configured per machine. Copy `files/git/signing.local.example` to
`~/.config/git/signing.local` and edit it.

## Reproducible tool versions (mise)

Global tools (neovim, node, go, python, rust, lazygit, claude-code, codex, copilot) are pinned in
`files/mise/config.toml`. To bump a version, edit it and run `mise install && mise lock`.

For a project, copy a starter and install:

```sh
cp ~/devup/templates/rust/mise.toml .
mise trust && mise install
```

Languages are pinned by mise. System libraries (clang, pkg-config, openssl, ...) come from the
OS package manager and are listed in comments inside each template.

## Tests

`tests/run-arch.sh` and `tests/run-fedora.sh` run the playbook twice in a clean container and fail
unless the second run changes nothing. CI also runs `ansible-lint` and a macOS syntax check.
