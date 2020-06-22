#!/bin/bash

## set -x	## Uncomment for debugging

## Include vars if the file exists
FILE=./vars.sh
if [ -f "$FILE" ]; then
  source ./vars.sh
else
  echo -e "ERROR: Variable file not found!\n"
  exit
fi

function promptCheckSubscription {
    echo -e "\n================================================================================"
    read -p "Have you subscribed this Red Hat Enterprise Linux System to a Satellite Infrastructure subscription? [N/y] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Moving on..."
    else
        exit
    fi
}

echo -e "\n================================================================================"
echo -e "Starting Satellite setup...\n"

## Set Hostname...
hostnamectl set-hostname $SATELLITE_HOSTNAME

## Set interface to be static and autoconnect...
if [ $ENABLE_DHCP = "true" ]; then
  #nmcli con edit $DHCP_INTERFACE
fi

## [DIY] Subscribe...
promptCheckSubscription

## Reboot to load new kernel
if [ -f "/opt/.init-complete" ]; then
  echo "Already finished initial setup and reboot..."
else
  ## Set Repos needed for Satellite...
  subscription-manager repos --disable "*"
  subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-satellite-6.7-rpms --enable=rhel-7-server-satellite-maintenance-6-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-ansible-2.8-rpms --enable=rhel-7-server-rh-common-rpms

  ## Disable Meltdown/Spectre patches to reclaim performance
  if [ $DISABLE_SPECTRE_PATCHES = "true" ]; then
    grubby --update-kernel=ALL --args="spectre_v2=off nopti"
  fi

  ## Install Packages
  yum clean all
  yum update -y
  yum install satellite nano ovirt-guest-agent-common chrony sos -y

  ## Setup Firewall
  firewall-cmd --add-port="80/tcp" --add-port="443/tcp" --add-port="5647/tcp" --add-port="8000/tcp" --add-port="8140/tcp" --add-port="9090/tcp" --add-port="53/udp" --add-port="53/tcp" --add-port="67/udp" --add-port="69/udp" --add-port="5000/tcp"
  firewall-cmd --runtime-to-permanent

  ## Set System Services
  systemctl start ovirt-guest-agent
  systemctl enable ovirt-guest-agent
  systemctl start qemu-guest-agent
  systemctl enable qemu-guest-agent
  systemctl start chronyd
  systemctl enable chronyd
  
  touch /opt/.init-complete
  systemctl reboot
fi

## Install Satellite
if [ -f "/opt/.satellite-init-complete" ]; then
  echo "Satellite already installed..."
else

  satellite-installer --scenario satellite \
--foreman-initial-admin-username $SATELLITE_ADMIN_USERNAME \
--foreman-initial-admin-password $SATELLITE_ADMIN_PASSWORD \
--foreman-initial-admin-email "${SATELLITE_ADMIN_EMAIL}" \
--foreman-initial-admin-first-name $SATELLITE_ADMIN_FIRST_NAME \
--foreman-initial-admin-last-name $SATELLITE_ADMIN_LAST_NAME \
--foreman-initial-organization "${SATELLITE_INITIAL_ORGANIZATION}" \
--foreman-initial-location "${SATELLITE_INITIAL_LOCATION}" \
--foreman-proxy-puppetca true \
--enable-foreman-plugin-discovery \
--enable-foreman-compute-ovirt \
--enable-foreman-compute-vmware \
--certs-node-fqdn "${SATELLITE_HOSTNAME}.${SATELLITE_DOMAIN}" \
--foreman-proxy-content-parent-fqdn "${SATELLITE_HOSTNAME}.${SATELLITE_DOMAIN}" \
--foreman-proxy-dhcp $ENABLE_DHCP \
--foreman-proxy-dhcp-managed $ENABLE_DHCP \
--foreman-proxy-dhcp-gateway "${DHCP_GATEWAY}" \
--foreman-proxy-dhcp-interface "${DHCP_INTERFACE}" \
--foreman-proxy-dhcp-nameservers "${DHCP_NAMESERVERS}" \
--foreman-proxy-dhcp-range "${DHCP_RANGE}" \
--foreman-proxy-dhcp-server "${DHCP_SERVER}" \
--foreman-proxy-dns $ENABLE_DNS \
--foreman-proxy-dns-managed $ENABLE_DNS \
--foreman-proxy-dns-forwarders "${DNS_FORWARDERS}" \
--foreman-proxy-dns-interface "${DNS_INTERFACE}" \
--foreman-proxy-dns-reverse "${DNS_REVERSE}" \
--foreman-proxy-dns-server "${DNS_SERVER}" \
--foreman-proxy-dns-zone "${DNS_ZONE}" \
--foreman-proxy-tftp $ENABLE_TFTP \
--foreman-proxy-tftp-managed $ENABLE_TFTP \
--foreman-proxy-tftp-servername "${TFTP_SERVERNAME}" \
--foreman-proxy-httpboot $ENABLE_HTTPBOOT \
--foreman-proxy-http $ENABLE_HTTPBOOT \
--foreman-proxy-httpboot-listen-on "${HTTPBOOT_INTERFACE_LISTEN_ON}"


  touch /opt/.satellite-init-complete
  
fi

## Next...

## 1. Make a Subscription Allocation + Download Manifest from Red Hat Customer Portal
## 2. Import Manifest into Satellite Subscriptions
# Continue to https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/installing_satellite_server_from_a_connected_network/installing_satellite_server#Managing_Subscriptions-Creating_a_Subscription_Manifest

echo -e "\n================================================================================"
read -p "Have you created a Subscription Allocation in the Red Hat Customer Portal and imported the Manifest into the Satellite Web UI? [N/y] " -n 1 -r
echo -e "\nCheck the following documentation for additional guidance: https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/installing_satellite_server_from_a_connected_network/installing_satellite_server#Managing_Subscriptions-Creating_a_Subscription_Manifest"
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Moving on..."
else
    exit
fi

## 3. Install Insights client & register
if [ $INSTALL_INSIGHTS_CLIENT = "true" ]; then
  satellite-maintain packages install insights-client
  insights-client --register
fi

## 4. Enable Satellite Tools repo on Satellite Server (where virt-who is running) and sync the repo down - also enable other repos for RHEL
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" \
--product 'Red Hat Enterprise Linux Server' \
--basearch='x86_64' \
--releasever='7Server' \
--name 'Red Hat Satellite Tools 6.7 (for RHEL 7 Server) (RPMs)'

hammer repository synchronize --organization "$SATELLITE_INITIAL_ORGANIZATION" \
--product 'Red Hat Enterprise Linux Server' \
--name 'Red Hat Satellite Tools 6.7 for RHEL 7 Server RPMs x86_64 7Server' \
--async

hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Virt V2V Tool for RHEL 7 (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Insights 3 (for RHEL 7 Server) (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
hammer repository-set enable --organization "$SATELLITE_INITIAL_ORGANIZATION" --product 'Red Hat Enterprise Linux Server' --releasever='7Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'

## Sync all the rest with...
hammer product synchronize \
--name "Red Hat Enterprise Linux Server" \
--organization "$SATELLITE_INITIAL_ORGANIZATION" \
--async

## Create a syncronizuation plan...
hammer sync-plan create \
--name "Red Hat Products" \
--description "Example Sync Plan for Red Hat Products" \
--interval daily \
--sync-date "2020-05-18 12:00:00" \
--enabled true \
--organization "$SATELLITE_INITIAL_ORGANIZATION"

hammer product set-sync-plan \
--name "Red Hat Enterprise Linux Server" \
--sync-plan "Red Hat Products" \
--organization "$SATELLITE_INITIAL_ORGANIZATION"

## EXAMPLE
## For Custom Products...
#### hammer sync-plan create \
#### --name "Kemo Labs Projects" \
#### --description "Sync Plan for stuff brewed out of Kemo Labs" \
#### --interval daily \
#### --sync-date "2020-05-18 12:00:00" \
#### --enabled true \
#### --organization "$SATELLITE_INITIAL_ORGANIZATION"

## 5. Deploy Virt-who on Satellite server to connect to RHV (via GUI)
## 6. Create satelliteLink user on RHVM - see file `/bash-scripts/create-rhv-user.sh`
## 7. Create new privateInternal (privint) Logical Network on RHVM - Compute > Data Center > Default > Logical Networks
## 8. Create Domain in Satellite - Infrastructure > Domain.  Associate to Org/Location
## 9. Create Subnet in Satellite - https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/quick_start_guide/associating_objects_with_the_default_organization_and_location#configuring_subnet
## 10. Create Content View in Satellite - https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/quick_start_guide/managing_and_promoting_content#creating_content_view
## 11. Add Repos to Content View && Publish New Version of Content View, then Promote Content View to additional Lifecycle Environment Path Envs
## 12. Create Activation Key in Satellite, generates:  rpm -Uvh http://satellite.kemo.labs/pub/katello-ca-consumer-latest.noarch.rpm && subscription-manager register --org="Kemo_Labs" --activationkey="kemoKey"
## 13. Skip...
## 14. Create a new RHEL VM in RHV - susbscribe to the Satellite Server, Install Clout-init, create Template in RHV from the VM
## 15. Create a Product for the RH Container Catalog, add to Refd Hat Products sync plan, add Kemo Labs PV mirror too

# hammer product create \
# --name "Red Hat Container Catalog" \
# --sync-plan "Red Hat Products" \
# --description "Red Hat Container Catalog content" \
# --organization "$SATELLITE_INITIAL_ORGANIZATION"
# 
# hammer repository create \
# --name "RHEL7" \
# --content-type "docker" \
# --url "http://registry.access.redhat.com/" \
# --docker-upstream-name "rhel7" \
# --product "Red Hat Container Catalog" \
# --organization "$SATELLITE_INITIAL_ORGANIZATION"
# 
# hammer repository create --name "UBI7" --content-type "docker" --url "http://registry.access.redhat.com/" --docker-upstream-name "ubi7" --product "Red Hat Container Catalog" --organization "Kemo Labs"
# 
# hammer repository synchronize \
# --name "RHEL7" \
# --product "Red Hat Container Catalog" \
# --organization "$SATELLITE_INITIAL_ORGANIZATION" \
# --async
# 
# hammer repository synchronize --name "UBI7" --product "Red Hat Container Catalog" --organization "$SATELLITE_INITIAL_ORGANIZATION" --async
# 
# hammer product create --name "Kemo Labs Private Container Catalog" --sync-plan "Kemo Labs Projects" --description "Kemo Labs Harbor Container Catalog content" --organization "$SATELLITE_INITIAL_ORGANIZATION"
# hammer repository create --name "PolyglotAcademyNPB" --content-type "docker" --url "https://harbor.polyglot.host/" --docker-upstream-name "polyglot-academy/pa-nginx-php-base" --product "Kemo Labs Private Container Catalog" --organization "$SATELLITE_INITIAL_ORGANIZATION" --verify-ssl-on-sync false --upstream-username 'robot$satellite' --upstream-password someReallyLoongThing
# hammer repository create --name "PolyglotAcademyNPNB" --content-type "docker" --url "https://harbor.polyglot.host/" --docker-upstream-name "polyglot-academy/pa-nginx-php-node-base" --product "Kemo Labs Private Container Catalog" --organization "$SATELLITE_INITIAL_ORGANIZATION" --verify-ssl-on-sync false --upstream-username 'robot$satellite' --upstream-password someReallyLoongThing
# hammer repository synchronize --name "PolyglotAcademyNPB" --product "Kemo Labs Private Container Catalog" --organization "$SATELLITE_INITIAL_ORGANIZATION" --async
# hammer repository synchronize --name "PolyglotAcademyNPNB" --product "Kemo Labs Private Container Catalog" --organization "$SATELLITE_INITIAL_ORGANIZATION" --async
# 
# 
# ## Sat + RHV
# ## https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/provisioning_guide/provisioning_virtual_machines_in_red_hat_virtualization
# 
# ## 16. Create Infrastructure > Compute Resource link with RHV in Satellite
# 
# hammer compute-resource create \
# --name "My_RHV" --provider "Ovirt" \
# --description "RHV server at manager.kemo.labs" \
# --url "https://manager.kemo.labs/ovirt-engine/api" \
# --use-v4 "true" --user "satelliteLink" \
# --password "securePassword" \
# --locations "$SATELLITE_INITIAL_LOCATION" --organizations "$SATELLITE_INITIAL_ORGANIZATION" \
# --datacenter "Default"
# 
# ## 17. In RHV Create Instance Types (1C1G, 2C2G, etc)
# ## 18. In Satellite create Compute Profiles that match the RHV Instance Types
# ## 19. In Satellite create Host Groups for Dev/Prod/etc
# ## 20. In Satellite - Infrastructure > Compute Resources > N > Images, create a new Image matching the Template in RHV
# 
# ## Setup/Reconfigure Satellite as a DHCP/DNS/TFTP server
# #### satellite-installer --scenario satellite --foreman-proxy-dhcp true \
# #### --foreman-proxy-dhcp-managed true \
# #### --foreman-proxy-dhcp-gateway "192.168.44.1" \
# #### --foreman-proxy-dhcp-interface "eth1" \
# #### --foreman-proxy-dhcp-nameservers "192.168.44.10" \
# #### --foreman-proxy-dhcp-range "192.168.44.100 192.168.44.200" \
# #### --foreman-proxy-dhcp-server "192.168.44.10" \
# #### --foreman-proxy-dns true \
# #### --foreman-proxy-dns-managed true \
# #### --foreman-proxy-dns-forwarders "192.168.44.1; 192.168.42.5" \
# #### --foreman-proxy-dns-interface "eth1" \
# #### --foreman-proxy-dns-reverse "44.168.192.in-addr.arpa" \
# #### --foreman-proxy-dns-server "127.0.0.1" \
# #### --foreman-proxy-dns-zone "satellite.labs" \
# #### --foreman-proxy-tftp true \
# #### --foreman-proxy-tftp-managed true \
# #### --foreman-proxy-tftp-servername "192.168.44.10" \
# #### --foreman-proxy-httpboot true \
# #### --foreman-proxy-http true \
# #### --foreman-proxy-httpboot-listen-on "both"
# 
# 
# ## Deploy Custom SSL Certificates: https://access.redhat.com/documentation/en-us/red_hat_satellite/6.7/html/installing_satellite_server_from_a_connected_network/performing_additional_configuration_on_satellite_server#configuring-satellite-custom-server-certificate_satellite
# 
# 
# 
