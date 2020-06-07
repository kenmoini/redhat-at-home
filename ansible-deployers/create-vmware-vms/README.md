# create-vmware-vms

## Deploy VMs on VMWare vSphere with Ansbile

### Prerequisites

#### Install the VMWare Automation SDK

```bash
pip install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
```

#### Set up VMWare SSL Certificates

See https://docs.ansible.com/ansible/latest/scenario_guides/vmware_scenarios/vmware_requirements.html

***Alternatively, both of those steps are done via the `tasks/local_vmware_setup.yaml` task***

### How to use

1. Fork this repo
2. Clone it down
3. Copy `vars/example.vcenter_vars.yml` to `vars/vcenter_vars.yml` and `vars/example.vcenter_password.yml` to `vars/vcenter_password.yml`
4. Modify as needed for authentication
5. Encrypt your password with Ansible Vault: `ansible-vault encrypt vars/vcenter_password.yml`
6. Inspect playbooks and use as you see fit: `ansible-playbook --ask-vault-pass create_vm_from_template.yml`