#!/bin/bash

echo "🚀 Starting DB VM (db01) setup..."
# vagrant up db01

vagrant ssh db01 -c 'bash -s' <<'OUTER_EOF'
  echo '✅ Logged into db01 VM'

  echo '📦 Updating system...'
  sudo dnf update -y

  echo '📥 Installing epel-release, git, mariadb-server...'
  sudo dnf install epel-release git mariadb-server -y

  echo '🚀 Starting & Enabling MariaDB...'
  sudo systemctl start mariadb
  sudo systemctl enable mariadb

    echo "🔐 Securing MySQL root user & config..."

  sudo mysql -e "
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123';
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
  "

  echo "💾 Step 6: Creating database and users..."

  sudo mysql -u root -padmin123 <<'INNER_EOF'
DROP DATABASE IF EXISTS accounts;
CREATE DATABASE accounts;

DROP USER IF EXISTS 'admin'@'%';
DROP USER IF EXISTS 'admin'@'localhost';
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin123';

GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%';
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
INNER_EOF

  echo "📦 Cloning DB source & importing..."
  cd /tmp/
  git clone -b local https://github.com/hkhcoder/vprofile-project.git
  cd vprofile-project
  sudo mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql

  echo "🧾 Verifying tables..."
  sudo mysql -u root -padmin123 -e "USE accounts; SHOW TABLES;"

  echo "🔥 Configuring firewall & restarting MariaDB..."
  sudo systemctl restart mariadb
  sudo systemctl start firewalld
  sudo systemctl enable firewalld
  sudo firewall-cmd --get-active-zones
  sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
  sudo firewall-cmd --reload
  sudo systemctl restart mariadb

  echo '✅ DB setup and configuration complete.'
OUTER_EOF