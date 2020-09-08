NFS Server
=========

Simply put, this configures a RHEL/CentOS machine as a NFS Server.  

It is preconfigured to set up 3 exports to support a Red Hat Virtualization environment.

Requirements
------------

None?

Role Variables
--------------

***defaults/main.yml***

```yaml
nfs_server_package_list:
  - nfs-utils
  - rpcbind
  - firewalld

firewall_service_configuration:
  - nfs
  - rpc-bind
  - mountd

mount_options: "(rw,sync,no_all_squash,root_squash)"

update_system_packages: true
restart_after_update: true
```

***vars/main.yml***

```yaml
# Don't forget the trailing slash!
base_nfs_export_path: /mnt/nfs_exports/

nfs_exports:
  - name: rhv-manager
    path: rhv-manager
    group: nobody
    owner: nobody
    mode: 0777
    network_address: 192.168.0.0/16

  - name: rhv-vms
    path: rhv-vms
    group: nobody
    owner: nobody
    mode: 0777
    network_address: 192.168.0.0/16

  - name: isos
    path: isos
    group: nobody
    owner: nobody
    mode: 0777
    network_address: 192.168.0.0/16
```

Dependencies
------------

None

Example Playbook
----------------

In case you want to override the default exports or variable configuration:

```yaml
- hosts: nfs_servers
  roles:
      - role: kenmoini.nfs_server
        vars:
          base_nfs_export_path: /mnt/exports_dir
          nfs_exports:
            - name: yourExport
              path: export-dir
              group: nobody
              owner: nobody
              mode: 0777
              network_address: 10.0.0.0/16
```

License
-------

MIT

Author Information
------------------

You can reach the author, Ken Moini, via [GitHub](https://github.com/kenmoini), or his [personal site](https://kenmoini.com).
