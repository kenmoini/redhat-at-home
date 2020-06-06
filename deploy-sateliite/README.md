# Deploy Red Hat Satellite

This folder houses a series of resources used to deploy a robust Red Hat Satellite server with optional features such as DHCP, DNS, TFTP PXE Boot, and more.

## Assumptions:

- Satellite VM with 2 NICs (eth0 & eth1).
- eth0 = static IP from 192.168.42.0/24 @satellite.kemo.labs.  
- Satellite will serve network services over eth1 with a static IP of 192.168.44.10

## How to use

1. Copy `example.vars.sh` to `vars.sh`
2. Review the `deploy.sh` file
3. Run as a whole, or in parts

There is additional guidance on how to sync Docker containers, integrate with RHV, and VMWare.