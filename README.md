
# vProfile Project Setup (Mac M1/M2)

This project sets up a microservices-based vProfile application using Vagrant and VirtualBox on a Mac M1/M2 system.

---

## Prerequisites

Install the following before starting:

- [Oracle VM VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- Git Bash (or Terminal with Unix shell support)

Install required Vagrant plugin:

```bash
vagrant plugin install vagrant-hostmanager
```

---

##  Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/tkmkushwah/vprofile-multi-tier-deployment.git
cd vprofile-multi-tier-deployment
cd vagrant/Manual_provisioning_MacOSM1
```

### 2. Start the VMs

```bash
vagrant up
```

> If the setup stops midway, just re-run `vagrant up`.

This will automatically update hostnames and `/etc/hosts` entries.

---

## Services Overview

| Service       | Description            |
|---------------|------------------------|
| MySQL         | Database               |
| Memcached     | DB Caching             |
| RabbitMQ      | Message Broker         |
| Tomcat        | Application Server     |
| Nginx         | Web Server             |

Provisioning order is **important**:

> 1. MySQL 2. Memcached 3. RabbitMQ  4. Tomcat  5. Nginx

---

##  MySQL Setup (VM: `db01`)

```bash
vagrant ssh db01
sudo -i
dnf update -y
dnf install epel-release git mariadb-server -y
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation
```

Use `admin123` as the root password during secure installation.

### Create DB & Import Data

```bash
mysql -u root -padmin123
# Inside MySQL shell:
CREATE DATABASE accounts;
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost' IDENTIFIED BY 'admin123';
FLUSH PRIVILEGES;
exit
```

```bash
cd /tmp
git clone -b local https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql
systemctl restart mariadb
```

### Configure Firewall

```bash
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload
```

---

## ⚡ Memcached Setup (VM: `mc01`)

```bash
vagrant ssh mc01
sudo -i
dnf update -y
dnf install memcached -y
systemctl start memcached
systemctl enable memcached
```

Update config to allow external connections:

```bash
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
systemctl restart memcached
```

### Configure Firewall

```bash
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=11211/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --add-port=11111/udp
firewall-cmd --runtime-to-permanent
memcached -p 11211 -U 11111 -u memcached -d
```

---

## RabbitMQ Setup (VM: `rmq01`)

```bash
vagrant ssh rmq01
sudo -i
dnf update -y
dnf install wget -y
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
systemctl enable --now rabbitmq-server
```

Setup user and permissions:

```bash
echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
systemctl restart rabbitmq-server
```

### Configure Firewall

```bash
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=5672/tcp
firewall-cmd --runtime-to-permanent
```

---

## Tomcat Setup (VM: `app01`)

```bash
vagrant ssh app01
sudo -i
dnf update -y
dnf install java-17-openjdk java-17-openjdk-devel git wget -y
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz
tar xzvf apache-tomcat-10.1.26.tar.gz
useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat
cp -r apache-tomcat-10.1.26/* /usr/local/tomcat
chown -R tomcat:tomcat /usr/local/tomcat
```

Create Tomcat systemd service:

```bash
vi /etc/systemd/system/tomcat.service
```

(Paste unit file content from PDF)

```bash
systemctl daemon-reload
systemctl enable --now tomcat
```

### Configure Firewall

```bash
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

---

##  Code Build & Deploy (On `app01`)

Install Maven:

```bash
cd /tmp
wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip
unzip apache-maven-3.9.9-bin.zip
cp -r apache-maven-3.9.9 /usr/local/maven3.9
export MAVEN_OPTS="-Xmx512m"
```

Build and deploy app:

```bash
git clone -b local https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
vim src/main/resources/application.properties
# Update DB, Memcache, RabbitMQ host entries

/usr/local/maven3.9/bin/mvn install
systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT*
cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
chown tomcat:tomcat /usr/local/tomcat/webapps -R
systemctl restart tomcat
```

---

## 🌐 Nginx Setup (VM: `web01`)

```bash
vagrant ssh web01
sudo -i
apt update && apt upgrade -y
apt install nginx -y
```

Create Nginx config:

```bash
vi /etc/nginx/sites-available/vproapp
```

```nginx
upstream vproapp {
    server app01:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://vproapp;
    }
}
```

Enable the site:

```bash
rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
systemctl restart nginx
```

---

## ✅ Final Verification

- Visit: `http://web01` (or mapped IP) to access the vProfile web UI.

---

## 👨‍💻 Author

**Tikam Singh**  

