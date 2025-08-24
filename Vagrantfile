# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set the number of managed nodes you want to create.
NUM_MANAGED_NODES = 1

# Set the Ansible version to install (use 'latest' for newest version)
# For Ansible community package: "latest", "11.2", "10.5", "9.8", etc.
# For ansible-core: "core-2.17.5", "core-2.16.14", "core-2.15.12", etc.
ANSIBLE_VERSION = "latest"  # Examples: "latest", "11.2", "10.5", "9.8", "core-2.17.5", "core-2.16.14"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "ansible-control" do |control|
    control.vm.hostname = "ansible-control"
    control.vm.network "private_network", ip: "192.168.56.10"

    control.vm.provider :virtualbox do |vb|
      vb.memory = 2048
    end

    control.vm.synced_folder "./ansible", "/home/vagrant/ansible", owner: "vagrant", group: "vagrant", mount_options: ["dmode=755,fmode=644"]

    control.vm.provision "shell", path: "bootstrap-control.sh", args: [NUM_MANAGED_NODES, ANSIBLE_VERSION]

    control.vm.provision "file", source: ".vimrc", destination: "/home/vagrant/.vimrc"

    control.vm.provision "shell", inline: <<-SHELL
      echo '>>> Adding shell aliases to .bashrc...'
      cat >> /home/vagrant/.bashrc <<-'EOF'

# Ansible Aliases
alias ap='ansible-playbook'
alias apv='ansible-playbook -v'
alias apvv='ansible-playbook -vv'
alias apc='ansible-playbook --check'
alias ad='ansible-doc'
alias ag='ansible-galaxy'

# General Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
EOF
    SHELL

    control.vm.provision "shell", args: NUM_MANAGED_NODES, inline: <<-SHELL
      NUM_NODES=$1
      echo ">>> Setting up Ansible configuration and SSH keys for $NUM_NODES managed nodes..."

      sudo -u vagrant mkdir -p /home/vagrant/ansible

      if [ ! -f /home/vagrant/.ssh/ansible_key ]; then
        sudo -u vagrant ssh-keygen -t ed25519 -f /home/vagrant/.ssh/ansible_key -N "" -C "ansible@vagrant-environment"
        echo ">>> Generated new SSH key pair for Ansible"
      else
        echo ">>> Using existing SSH key pair"
      fi

      mkdir -p /vagrant/.ssh
      cp /home/vagrant/.ssh/ansible_key.pub /vagrant/.ssh/
      chmod 644 /vagrant/.ssh/ansible_key.pub

      cat /home/vagrant/.ssh/ansible_key.pub >> /home/vagrant/.ssh/authorized_keys

      sudo -u vagrant cat > /home/vagrant/ansible/inventory <<EOF
[managed_nodes]
EOF

      for i in $(seq 1 $NUM_NODES); do
        IP=$((10 + i))
        echo "managed-node-$i ansible_host=192.168.56.$IP" | sudo -u vagrant tee -a /home/vagrant/ansible/inventory > /dev/null
      done

      sudo -u vagrant cat >> /home/vagrant/ansible/inventory <<EOF

[cluster:children]
managed_nodes
EOF

      sudo -u vagrant cat > /home/vagrant/ansible/ansible.cfg <<'EOF'
[defaults]
inventory = inventory
remote_user = vagrant
private_key_file = /home/vagrant/.ssh/ansible_key
host_key_checking = False
deprecation_warnings = False
timeout = 30
interpreter_python = /usr/bin/python3
EOF

      echo ">>> Ansible configuration completed for $NUM_NODES managed nodes!"
      echo ">>> After all VMs are up, test with: ansible all -m ping"
    SHELL
  end

  (1..NUM_MANAGED_NODES).each do |i|
    config.vm.define "managed-node-#{i}" do |node|
      node.vm.hostname = "managed-node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"

      node.vm.provider :virtualbox do |vb|
  vb.memory = 2048
      end

      node.vm.provision "shell", inline: <<-SHELL
        echo '>>> Configuring SSH on managed node...'

        systemctl enable ssh
        systemctl start ssh

        chmod 700 /home/vagrant/.ssh/
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh/

        echo '>>> Managed node SSH configuration completed!'
      SHELL

      node.vm.provision "shell", inline: <<-SHELL
        echo '>>> Setting up Ansible SSH access...'

        mkdir -p /tmp/ansible-setup

        # This will be executed after the control node is fully provisioned
        until [ -f /vagrant/.ssh/ansible_key.pub ]; do
          echo ">>> Waiting for Ansible SSH key to be available..."
          sleep 2
        done

        cat /vagrant/.ssh/ansible_key.pub >> /home/vagrant/.ssh/authorized_keys

        sort /home/vagrant/.ssh/authorized_keys | uniq > /tmp/auth_keys_clean
        mv /tmp/auth_keys_clean /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

        echo ">>> Ansible SSH access configured successfully!"
      SHELL
    end
  end
end
