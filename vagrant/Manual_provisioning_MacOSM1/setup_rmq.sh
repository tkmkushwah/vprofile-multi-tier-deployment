echo "Starting RabbitMQ VM (rmq01) setup..."
vagrant up rmq01

vagrant ssh rmq01 -c 'bash -s' <<'EOF'
echo "Logged into rmq01 VM"

echo "Updating system..."
sudo dnf update -y

echo "Installing wget"
sudo dnf install wget -y

echo "Installing RabbitMQ dependencies..."
sudo dnf -y install centos-release-rabbitmq-38
sudo dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server

echo "Enabling and starting RabbitMQ service..."
sudo systemctl enable --now rabbitmq-server

echo "Fixing hostname issue for RabbitMQ..."
sudo sh -c "echo '127.0.0.1   $(hostname)' >> /etc/hosts"

echo "Configuring RabbitMQ loopback users..."
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'

sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
sudo rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

echo "Restarting RabbitMQ to apply changes..."
sudo systemctl restart rabbitmq-server

sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --add-port=5672/tcp
sudo firewall-cmd --runtime-to-permanent
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl status rabbitmq-server


echo "This is complete"
EOF