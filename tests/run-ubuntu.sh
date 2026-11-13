#!/usr/bin/env bash
# Full run of the playbook in a clean Ubuntu container, then an idempotence check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

engine=$(command -v docker || command -v podman)

"$engine" run --rm --security-opt label=disable -v "$PWD":/devup:ro "ubuntu:${UBUNTU_VERSION:-24.04}" bash -euo pipefail -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends ansible-core git python3-apt ca-certificates sudo
  # Minimal images exclude /usr/share/doc, including fzf shell integration.
  printf "path-include=/usr/share/doc/fzf/examples/*.zsh\n" > /etc/dpkg/dpkg.cfg.d/zz-devup-fzf
  useradd -m -s /bin/bash tester
  echo "tester ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tester
  cp -r /devup /home/tester/devup && chown -R tester /home/tester/devup
  su tester -c "bash -euo pipefail" <<"EOF"
    cd ~/devup
    ansible-galaxy collection install -r requirements.yml
    export ANSIBLE_STDOUT_CALLBACK=default
    mkdir -p ~/.local/bin
    printf "#!/bin/sh\nexit 99\n" > ~/.local/bin/mise
    chmod +x ~/.local/bin/mise
    export PATH="$HOME/.local/bin:$PATH"
    mkdir -p ~/.config/mise/conf.d
    printf "[tools]\nfzf = \"latest\"\n" > ~/.config/mise/conf.d/ubuntu.toml
    for package in du-dust starship; do
      if [[ -n "$(apt-cache madison "$package")" ]]; then
        binary=${package/du-dust/dust}
        sudo mkdir -p /usr/local/bin
        sudo ln -s "/opt/devup/$package-0.0.0/$binary" "/usr/local/bin/$binary"
      fi
    done
    ansible-playbook site.yml -e ci_container=true
    ansible-playbook site.yml -e ci_container=true | tee /tmp/second.log
    grep -Eq "changed=0 .*failed=0" /tmp/second.log
    test ! -d ~/.local/share/mise/installs/npm
    test ! -e ~/.config/mise/conf.d/ubuntu.toml
    for package in git-delta just fzf bottom; do
      dpkg-query -W -f='"'"'${Status}\n'"'"' "$package" | grep -Fx "install ok installed"
    done
    if apt-cache madison du-dust | grep -q .; then test ! -L /usr/local/bin/dust; fi
    if apt-cache madison starship | grep -q .; then test ! -L /usr/local/bin/starship; fi
    cd "$HOME"
    # The fake mise prevents activation; shell utilities must still work.
    env PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" zsh -ic '"'"'
      set -e
      for widget in omz history-substring-search-up _zsh_autosuggest_start _zsh_highlight fzf-file-widget; do
        typeset -f "$widget" >/dev/null
      done
      for tool in bat fd eza fzf starship delta btm dust just yq mise; do
        command -v "$tool"
      done
      [[ "$(command -v fzf)" == /usr/bin/fzf ]]
      [[ "$(command -v delta)" == /usr/bin/delta ]]
      [[ "$(command -v just)" == /usr/bin/just ]]
      bat --version
      fd --version
      yq --version | grep mikefarah
    '"'"'
    rm ~/.local/bin/mise
    mise exec -- python -c "import sys; assert sys.version_info[:2] == (3, 13)"
EOF
'
