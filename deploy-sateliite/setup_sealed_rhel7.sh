#!/bin/bash

## This script will set up a RHEL7 VM to be sealed which will remove any identifying information and allow it to be easily converted to a template in a hypervisor

rpm -Uvh http://satellite.vmware.labs/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org="Satellite_Labs" --activationkey="RHEL7AK"

yum update -y
yum install nano initial-setup cloud-init -y

systemctl enable initial-setup.service

hostnamectl set-hostname localhost.localdomain

sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-*
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-*

chmod 777 /etc/machine-id
echo > /etc/machine-id

rm -rf /var/lib/dbus/machine-id
rm -rf /etc/ssh/ssh_host_*
rm -rf /etc/udev/rules.d/70-persistent-*

subscription-manager unregister
subscription-manager remove --all
subscription-manager clean
yum clean all

rm -f /etc/rhsm/facts/katello.facts

poweroff
