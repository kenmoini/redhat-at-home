#!/bin/bash

# This script assumes that the RHEL system has already been subscribed...

# Basic variables
ADMIN_PASSWORD="sup3rS3cr3t"
POSTGRES_PASSWORD="m4k3M3S4f3"

# Install firewalld, wget, nano, and cockpit
yum install -y wget nano firewalld cockpit-ws cockpit-dashboard cockpit-pcp cockpit-system cockpit-bridge cockpit

# Enable Firewalld
systemctl enable --now firewalld

# Add Cockpit and SSH to firewalld allowed services
firewall-cmd --permanent --add-service=cockpit
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Enable Cockpit
systemctl enable --now cockpit.service

# Download latest package
wget https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-latest.tar.gz

# Unzip
tar zxvf ansible-tower-setup-latest.tar.gz
rm ansible-tower-setup-latest.tar.gz
cd ansible-tower-setup-*

# Modify inventory file
cp inventory inventory.orig
sed -i "s/admin_password=''/admin_password='$ADMIN_PASSWORD'/g" inventory
sed -i "s/pg_password=''/pg_password='$POSTGRES_PASSWORD'/g" inventory

# Run setup
./setup.sh