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
  sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached

  echo ' Restarting Memcached to apply new config...'
  sudo systemctl restart memcached

  echo ' Configuring firewall to allow Memcached port...'
  sudo systemctl start firewalld
  sudo systemctl enable firewalld

  sudo firewall-cmd --add-port=11211/tcp
  sudo firewall-cmd --runtime-to-permanent
  sudo firewall-cmd --add-port=11111/udp
  sudo firewall-cmd --runtime-to-permanent
  sudo memcached -p 11211 -U 11111 -u memcached -d

  echo 'Memcached setup and configuration complete.'
EOF