#!/usr/bin/env bash

set -euo pipefail

NUM_NODES=$1
ANSIBLE_VERSION=$2

echo ">>> Updating package list..."
apt-get update -y

echo ">>> Installing dependencies (git, vim, tree, curl, python3-pip, etc.)..."
apt-get install -y git vim tree software-properties-common curl python3-pip python3-venv

echo ">>> Installing Ansible version: $ANSIBLE_VERSION using pip3..."

# Remove any existing Ansible installations from apt to avoid conflicts
echo ">>> Removing any existing apt-installed Ansible packages..."
apt-get remove -y ansible ansible-core ansible-lint 2>/dev/null || true

# Install Ansible based on version specification
if [ "$ANSIBLE_VERSION" = "latest" ]; then
  echo ">>> Installing latest Ansible community package version..."
  sudo -u vagrant pip3 install --user --break-system-packages --no-warn-script-location ansible ansible-lint
elif [[ "$ANSIBLE_VERSION" == core-* ]]; then
  # Extract version number from "core-X.Y.Z" format
  CORE_VERSION=${ANSIBLE_VERSION#core-}
  echo ">>> Installing ansible-core version $CORE_VERSION..."
  sudo -u vagrant pip3 install --user --break-system-packages --no-warn-script-location ansible-core==$CORE_VERSION ansible-lint
else
  echo ">>> Installing Ansible community package version $ANSIBLE_VERSION..."
  sudo -u vagrant pip3 install --user --break-system-packages --no-warn-script-location ansible==$ANSIBLE_VERSION ansible-lint
fi

echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vagrant/.bashrc

export PATH="/home/vagrant/.local/bin:$PATH"
INSTALLED_VERSION=$(sudo -u vagrant /home/vagrant/.local/bin/ansible --version 2>/dev/null | head -n1 || echo "ansible installation pending PATH reload")
echo ">>> Ansible installation completed. Installed version: $INSTALLED_VERSION"

echo ">>> System provisioning complete!"
echo ">>> NOTE: Ansible inventory and configuration will be created by Vagrant provisioning"
echo ">>> SSH into the control node with 'vagrant ssh ansible-control'"
echo ">>> Navigate to the synced folder: 'cd ~/ansible'"
echo ">>> Test with: 'ansible all -m ping' or use the alias 'ap playbooks/ping.yml'"
