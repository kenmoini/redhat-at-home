#!/bin/bash

# Subscribe...

subscription-manager repos --disable "*"
subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-satellite-6.7-rpms --enable=rhel-7-server-satellite-maintenance-6-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-ansible-2.8-rpms --enable=rhel-7-server-rh-common-rpms

grubby --update-kernel=ALL --args="spectre_v2=off nopti"

yum clean all

yum repolist enabled

yum update -y && systemctl reboot

yum install satellite nano ovirt-guest-agent-common chrony sos

firewall-cmd --add-port="80/tcp" --add-port="443/tcp" --add-port="5647/tcp" --add-port="8000/tcp" --add-port="8140/tcp" --add-port="9090/tcp" --add-port="53/udp" --add-port="53/tcp" --add-port="67/udp" --add-port="69/udp" --add-port="5000/tcp"
firewall-cmd --runtime-to-permanent

systemctl start ovirt-guest-agent
systemctl enable ovirt-guest-agent

systemctl start qemu-guest-agent
systemctl enable qemu-guest-agent

systemctl start chronyd
systemctl enable chronyd

yum update -y && systemctl reboot

satellite-installer --scenario satellite \
--foreman-initial-admin-username admin \
--foreman-initial-admin-password redhat \
--foreman-initial-admin-email "ken@kenmoini.com" \
--foreman-initial-admin-first-name Ken \
--foreman-initial-admin-last-name Moini \
--foreman-initial-organization "Kemo Labs" \
--foreman-initial-location "RH Lab" \
--foreman-proxy-puppetca true \
--foreman-proxy-tftp true \
--enable-foreman-plugin-discovery \
--enable-foreman-compute-ovirt \
--certs-node-fqdn satellite.kemo.labs \
--foreman-proxy-content-parent-fqdn satellite.kemo.labs


