#!/usr/bin/env bash
# Full run of the playbook in a clean Arch container, then an idempotence check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker run --rm -v "$PWD":/devup:ro archlinux:latest bash -euo pipefail -c '
  pacman -Syu --noconfirm ansible git sudo
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
  "
'
