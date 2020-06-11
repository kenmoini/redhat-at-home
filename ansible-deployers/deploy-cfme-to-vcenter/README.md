# Deploy Red Hat CloudForms to VMWare vSphere

Deploying Red Hat CloudForms Management Engine to vSphere isn't difficult, but why not automate it?  Especially for HA environments!

## What this does

1. Calls the shared Ansible Role `localVMWareSetup` which will set up your local Ansible environment with the SSL CA Certificate from your vCenter server and the needed packages/SDKs
2. Creates a local working directory to store the CFME OVA (need to download from Red Hat Customer Portal first)
3. Deploys the OVA to vCenter

## Prerequisites

***Alternatively, the SDK and SSL steps are done via the `localVMWareSetup` role***

### Install the VMWare Automation SDK

```bash
pip install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
```

### Set up VMWare SSL Certificates

See https://docs.ansible.com/ansible/latest/scenario_guides/vmware_scenarios/vmware_requirements.html

### CloudForms specific

- Download the latest Red Hat CloudForms OVA from the Red Hat Customer Portal.  Either store it locally or on an accessible server to be pulled in.
- Download the VMWare VDDK and use later to install in the CFME appliance: https://access.redhat.com/documentation/en-us/red_hat_cloudforms/5.0/html/installing_red_hat_cloudforms_on_vmware_vsphere/additional-configuration-vmware#installing-vmware-vddk

## How to Use

1. Download CFME OVA from Red Hat Customer Portal
2. Place somewhere accessible to the Ansible deployer, declare the needed variables
3. ???????
4. PROFIT!!!!!!1

### Using in Ansible Tower

1. Load this repo as a new Project
2. Ensure you have your VMWare credentials and Inventory Sync setup
3. Create a Template from this Playbook - use the following as extra variables, or as part of a Survey

```yaml
vcenter_server: vcenter.example.com
vcenter_username: administrator@example.com
vcenter_password: myvcenterpassword

ansibleWorkingDirectory: "/opt/.ansible-generated"

ovaLocation: filesystem
ovaPath: files/cfme-vsphere-paravirtual-5.11.6.0-1.x86_64.vsphere.ova
#ovaLocation: url
#ovaPath: https://ftp.example.com/files/cfme-vsphere-paravirtual-5.11.6.0-1.x86_64.vsphere.ova

new_vm_name: RH-CloudFormsME
new_vm_poweredon: no

vcenter_datacenter_name: Lab DC
vcenter_datastore_name: VMDataStore
vcenter_network_name: KL Network
```

## Post-deployment Instructions

- You'll first be presented with Cockpit available on https://IP:9090 - navigate to that, use the Terminal (or SSH in) and setup your subscriptions (default credentials are root/smartvm)
- Install VDDK on the appliance
- Attach another 20GB hard disk to the appliance VM for the PGSQL DB (could be ansible-ized...)
- Run `appliance_console` on the appliance
- Configure a new database (option 5), make sure to press N on the last prompt...
- Give it a few seconds and navigate to https://IP:443 and you'll be greeted with the CFME login page (default credentials are admin/smartvm)