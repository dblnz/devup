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

## After running the playbook

Some steps are manual:

1. **tmux plugins**: the playbook only clones TPM. Start `tmux` and press `prefix + I` (capital I) to
   install the plugins, or run `~/.tmux/plugins/tpm/bin/install_plugins`. Then reload with
   `tmux source ~/.tmux.conf`.
2. **Terminal font**: set your terminal's font to JetBrainsMono Nerd Font.
3. **Git signing**: copy `files/git/signing.local.example` to `~/.config/git/signing.local` and edit it.
4. **New shell**: open a new shell (or log out and in after the login shell changed to zsh), then check
   `mise ls`.

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
| `roles/snapper` | Opt-in automatic btrfs snapshots with snapper (hourly timeline + cleanup; Fedora/Arch) |
| `roles/framework_charge_limit` | Opt-in Framework laptop battery charge limit (`framework-system` from the Terra repo + systemd unit) |
| `templates/<lang>/mise.toml` | Starter per-project tool pins |

Per-machine overrides go in `host_vars/localhost.yml` (git-ignored):

```yaml
git_user_name: "Your Name"
git_user_email: you@example.com
macspoof_enabled: true
macspoof_interface: wlan0
snapper_enabled: true   # btrfs root only; override snapper_settings for retention
framework_charge_limit_enabled: true
framework_charge_limit_percent: 60
```

## Framework battery charge limit

`roles/framework_charge_limit` sets the limit with `framework_tool` and a systemd unit. On GNOME, the
[Battery Health Charging](https://extensions.gnome.org/extension/5724/battery-health-charging/) extension is an
alternative that sets the threshold from the shell. Note that a Framework firmware update can break it, which is why
this repo uses the systemd unit.

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
