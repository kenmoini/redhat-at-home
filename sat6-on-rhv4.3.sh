#!/bin/bash

subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-satellite-6.7-rpms --enable=rhel-7-server-satellite-maintenance-6-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-ansible-2.8-rpms --enable=rhel-7-server-rh-common-rpms

yum clean all

yum repolist enabled

yum update -y && systemctl reboot

yum install satellite nano ovirt-guest-agent-common

systemctl start ovirt-guest-agent
systemctl enable ovirt-guest-agent

systemctl start qemu-guest-agent
systemctl enable qemu-guest-agent

satellite-installer --scenario satellite \
--foreman-initial-admin-username admin \
--foreman-initial-admin-password redhat \
--foreman-proxy-puppetca true \
--foreman-proxy-tftp true \
--enable-foreman-plugin-discovery
