# create-vmware-vms

## Deploy VMs on VMWare vSphere with Ansbile

### Prerequisites

***Alternatively, both of those steps are done via the `localVMWareSetup` role***

#### Install the VMWare Automation SDK

```bash
pip install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
```

#### Set up VMWare SSL Certificates

See https://docs.ansible.com/ansible/latest/scenario_guides/vmware_scenarios/vmware_requirements.html


### How to use

1. Fork this repo
2. Clone it down
3. Copy `vars/example.vcenter_vars.yml` to `vars/vcenter_vars.yml` and `vars/example.vcenter_password.yml` to `vars/vcenter_password.yml`
4. Modify as needed for authentication
5. Encrypt your password with Ansible Vault: `ansible-vault encrypt vars/vcenter_password.yml`
6. Inspect playbooks and use as you see fit: `ansible-playbook --ask-vault-pass create_vm_from_template.yml`

#### Using in Ansible Tower

1. Load this repo as a new Project
2. Ensure you have your VMWare credentials and Inventory Sync setup
3. Create a Template from this Playbook - use the following as extra variables, or as part of a Survey

```yaml
vcenter_server: vcenter.example.com
vcenter_username: administrator@example.com
vcenter_password: myvcenterpassword

new_vm_name: NewVM
new_vm_state: poweredon
template_name: RHEL7.8GoldImage
vcenter_cluster_name: Default
vcenter_datacenter_name: DC1
vcenter_folder: /DC1/vm
```