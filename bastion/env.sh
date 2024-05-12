#!/bin/bash

# Environment for package check
packages=(git httpd httpd-tools podman haproxy bind bind-utils jq wget net-tools telnet nmap-ncat unzip telnet chrony nfs-utils)

# Environment for registry
CURRENTPATH=$(pwd)
## Registry Type (DockerRegistry ProjectQUAY)
SRC_REGISTRY_TYPE=ProjectQUAY
## Registry Base Path
SRC_REGISTRY_BASE=/app/quay
## Registry Domain Name for create Certificate
SRC_REGISTRY=container-registry.kcbcore.com
## Registry Authentication Information
SRC_REGISTRY_ID=admin
SRC_REGISTRY_PASS=Rkakrnl.47$
## Registry Listen Port (for Host, not container listen port)
SRC_REGISTRY_PORT=443

# Environment for DNS, haproxy
## Bastion IP
BA_IP=192.168.70.140
## Bootstrap Node IP
BS_IP=10.10.70.136
## Master Node IPs
M_IP=(10.10.70.131 10.10.70.132 10.10.70.133)
## Worker Node IPs
W_IP=(10.10.70.134 10.10.70.135)
## SNO installation?
SNO=false

# Environment for haproxy
## Haproxy config file name
haproxy_config_file="/etc/haproxy/haproxy.cfg"
## Haproxy config file name for backup
haproxy_backup_file="${haproxy_config_file}_$(date +"%Y%m%d-%H%M%S")"
## The content is written from the next line
haproxy_search_string="# main frontend which proxys to the backends"

# Environment for DNS
## Upstream DNS IP for forwarder config
upstream=192.168.23.2
## DNS config file name
dns_conf_filename=/etc/named.conf
## DNS rfc1912 config file name
dns_rfc1912_zone_filename=/etc/named.rfc1912.zones
## DNS Forwarder zone name
forward_zonename=okd4.sye.home
## DNS Forwarder zone file name
forward_filename=/var/named/$forward_zonename.zone
## DNS Reverse zone name
rev_zonename=70.10.10.in-addr.arpa
## DNS Reverse zone file name
rev_filename=/var/named/$rev_zonename.zone
