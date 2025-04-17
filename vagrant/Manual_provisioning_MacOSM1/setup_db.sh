#!/bin/bash

echo "Starting DB VM (db01) setup..."

vagrant ssh db01 -c "
  echo 'Logged into db01 VM'; 

echo 'Updating system...';
   sudo dnf update -y;

  echo 'Installing epel-release, git, mariadb-server...';
    sudo dnf install epel-release 
    sudo dnf install git mariadb-server -y;

  echo 'Starting & Enabling MariaDB...';
       sudo systemctl start mariadb;
       sudo systemctl enable mariadb;

  echo ' running mysql_secure_installation'
       sudo mysql_secure_installation;

       echo "done"
     "