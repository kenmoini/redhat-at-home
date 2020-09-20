# dns-core-knotdns

This Ansible content will configure a set of systems as DNS Authoritative and/or Resolving servers with Knot DNS and Knot Resolver!

## Usage

1. Create a set of VMs to act as Primary/Replica DNS Servers, set static IPs
2. Modify variable files to suit your needs
  - `defaults/main.yaml`
  - `vars/main.yaml`
  - `vars/dns_config.yaml`
3. Create a host inventory file with an additional variable for each host: `ansible_set_hostname=dns-core-Xn`
4. Run the `deploy.yaml` Playbook