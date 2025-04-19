
# Login to the tomcat vm
vagrant ssh app01
# Verify Hosts entry, if entries missing update the it with IP and hostnames
 cat /etc/hosts
# Update OS with latest patches
sudo dnf update -y
# Install Dependencies
sudo dnf -y install java-17-openjdk java-17-openjdk-devel

# Change dir to /tmp
cd /tmp/

wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz
tar xzvf apache-tomcat-10.1.26.tar.gz
