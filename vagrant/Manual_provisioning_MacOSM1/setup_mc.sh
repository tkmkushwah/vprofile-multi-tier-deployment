#!/bin/bash
vagrant up mc01
echo " Starting Memcached VM (mc01) setup..."
# vagrant up mc01

vagrant ssh mc01 -c 'bash -s' <<'EOF'
  echo ' Logged into mc01 VM'

  echo 'Updating system...'
  sudo dnf update -y

  echo 'Installing Memcached...'
  sudo dnf install memcached -y

  echo 'Starting & Enabling Memcached...'
  sudo systemctl start memcached
  sudo systemctl enable memcached

  echo 'Configuring Memcached to listen on all interfaces...'
  sudo sed -i 's/OPTIONS="-l 127.0.0.1"/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached

  echo ' Restarting Memcached to apply new config...'
  sudo systemctl restart memcached

  echo ' Configuring firewall to allow Memcached port...'
  sudo systemctl start firewalld
  sudo systemctl enable firewalld
  sudo firewall-cmd --zone=public --add-port=11211/tcp --permanent
  sudo firewall-cmd --reload

  echo 'Memcached setup and configuration complete.'
EOF