# rhv-vms

## Deploy and Manage VMs on Red Hat Virtualization with Ansbile

### Prerequisites

```bash
dnf install libcurl-devel libxml-devel
pip install ovirt-engine-sdk-python==4.2.4
```

### How to use

1. Fork this repo
2. Clone it down
3. Copy `vars/example.rhvm_vars.yml` to `vars/rhvm_vars.yml` and `vars/example.rhvm_password.yml` to `vars/rhvm_password.yml`
4. Modify as needed for authentication
5. Encrypt your password with Ansible Vault: `ansible-vault encrypt vars/rhvm_password.yml`
6. Inspect playbooks and use as you see fit: `ansible-playbook --ask-vault-pass create_centos_vm.yml`

The `create.yml` Playbook does the following:

- Downloads a CentOS ISO
- Imports the ISO into RHV
- Creates a VM Template
- Creates a VM with that template
- Boots the VM with cloud-init