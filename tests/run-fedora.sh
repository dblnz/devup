#!/usr/bin/env bash
# Full run of the playbook in a clean Fedora container, then an idempotence check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Fedora hosts usually have podman rather than docker, with SELinux enforcing.
engine=$(command -v docker || command -v podman)

"$engine" run --rm --security-opt label=disable -v "$PWD":/devup:ro fedora:latest bash -euo pipefail -c '
  dnf install -y ansible-core git python3-libdnf5 python3-libselinux sudo shadow-utils util-linux
  useradd -m -G wheel tester
  echo "tester ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tester
  cp -r /devup /home/tester/devup && chown -R tester /home/tester/devup
  su tester -c "
    cd ~/devup
    ansible-galaxy collection install -r requirements.yml
    export ANSIBLE_STDOUT_CALLBACK=default
    ansible-playbook site.yml -e ci_container=true
    ansible-playbook site.yml -e ci_container=true | tee /tmp/second.log
    grep -Eq \"changed=0 .*failed=0\" /tmp/second.log
    # zshrc loads oh-my-zsh and finds its plugins at Fedora paths
    zsh -ic \"typeset -f omz history-substring-search-up _zsh_autosuggest_start _zsh_highlight\" >/dev/null
  "
'
