#!/bin/bash

. ./env.sh

# backup org config with the current timestamp
cp -av "$dns_conf_filename" "${dns_conf_filename}_$(date +"%Y%m%d-%H%M%S")"
cp -av "$dns_rfc1912_zone_filename" "${dns_rfc1912_zone_filename}_$(date +"%Y%m%d-%H%M%S")"

# config named.conf
echo "Bind IP and allow quary to any."
sed -i 's/listen-on port 53 { 127.0.0.1; };/listen-on port 53 { any; };/g' $dns_conf_filename
sed -i 's/allow-query     { localhost; };/allow-query     { any; };/g' $dns_conf_filename


if ! grep -qw "forwarders" "$dns_conf_filename"; then
  echo "forwarders not found. add forwarders to $dns_conf_filename"
  sed -i "/^\s*recursion yes;/a\        forwarders { $upstream; };" "$dns_conf_filename"
fi

# config named.rfc1912.zones
if ! grep -qw "$forward_zonename" "$dns_rfc1912_zone_filename"; then
  echo "Add $forward_zonename zone to $dns_rfc1912_zone_filename"
    cat >> $dns_rfc1912_zone_filename << EOF

zone "$forward_zonename" IN {
    type master;
    file "$forward_zonename.zone";
    allow-update { none; };
};
EOF
fi

if ! grep -qw "$rev_zonename" "$dns_rfc1912_zone_filename"; then
  echo "Add $rev_zonename zone to $dns_rfc1912_zone_filename"

	cat >> $dns_rfc1912_zone_filename << EOF

zone "$rev_zonename" IN {
    type master;
    file "$rev_zonename.zone";
    allow-update { none; };
};
EOF
fi

# config forward zone file
cat > $forward_filename << EOF
\$ORIGIN $forward_zonename.
\$TTL 86400
@       IN SOA  ns.$forward_zonename. $forward_zonename (
                                       2020121700      ; serial
                                        1W              ; refresh
                                        1H              ; retry
                                        1W              ; expire
                                        1D      )       ; minimum
                IN      NS      ns.$forward_zonename.
ns              IN      A       $BA_IP
bastion         IN      A       $BA_IP

bootstrap       IN      A       $BS_IP

EOF

## Function to add servers to zonefile
add_servers_to_zonefile() {
    local node_type="$1"
    local ip_array_name="$2[@]"

    local ip_array=("${!ip_array_name}")
    for ((i=0; i<${#ip_array[@]}; i++)); do
      if [[ $SNO == "true" && $node_type == *"master"* ]]; then
            echo "sno    IN      A       ${ip_array[$i]}"
        elif [[ $SNO != "true" ]]; then
            echo "$node_type$((i+1))    IN      A       ${ip_array[$i]}"
        fi
    done
}

## Add servers for master node
add_servers_to_zonefile "master" "M_IP" >> $forward_filename

## Add servers for worker node
add_servers_to_zonefile "worker" "W_IP" >> $forward_filename

cat >> $forward_filename << EOF

*.apps          IN      A       $BA_IP
api             IN      A       $BA_IP
api-int         IN      A       $BA_IP
EOF



# config reverse zone file
cat > $rev_filename << EOF
\$ORIGIN $rev_zonename.
\$TTL 86400
@       IN SOA  ns.$forward_zonename. $forward_zonename (
                                       2020121700      ; serial
                                        1W              ; refresh
                                        1H              ; retry
                                        1W              ; expire
                                        1D      )       ; minimum
@       IN      NS      ns.$forward_zonename.
$(echo $BA_IP | cut -d '.' -f 4)        IN      PTR     ns.$forward_zonename.
$(echo $BA_IP | cut -d '.' -f 4)        IN      PTR     bastion.$forward_zonename.

$(echo $BS_IP | cut -d '.' -f 4)        IN      PTR     bootstrap.$forward_zonename.

EOF

## Function to add servers to zonefile
add_servers_to_revzonefile() {
    local node_type="$1"
    local ip_array_name="$2[@]"

    local ip_array=("${!ip_array_name}")
    for ((i=0; i<${#ip_array[@]}; i++)); do
        last_octet=$(echo ${ip_array[$i]} | cut -d '.' -f 4)
        if [[ $SNO == "true" && $node_type == *"master"* ]]; then
                echo "$last_octet       IN      PTR     sno.$forward_zonename."
        elif [[ $SNO != "true" ]]; then
                echo "$last_octet       IN      PTR     $node_type$((i+1)).$forward_zonename."
        fi
    done
}

## Add servers for master node
add_servers_to_revzonefile "master" "M_IP" >> $rev_filename

## Add servers for worker node
add_servers_to_revzonefile "worker" "W_IP" >> $rev_filename
