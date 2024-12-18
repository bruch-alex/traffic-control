#!/bin/bash

# Array to hold the IP groups by network
declare -A networks
declare last_network

# Grep and process IPs
grep xray /var/log/syslog | cut -d ' ' -f 9 | cut -d '=' -f 2 | sort -u >> temp_ips.txt 

while IFS= read -r ip; do
   
    if [ "$(geoiplookup "$ip" | cut -d ' ' -f 4)" != "RU" ]; then 
        continue
    fi
    
    echo "Processing IP: $ip"
    
    # Add IP to the group based on network address
    network=$(echo "$ip" | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]*\.[0-9]*/\1.0.0/')
    current_network="$network/16"
    # Check if it's null (or unset)
    if [ -z "$last_network" ]; then
        networks["$current_network"]=1
        last_network="$current_network"
    elif [ "$current_network" != "$last_network" ]; then
        echo "not equals"
        networks["$current_network"]=1
        last_network="$current_network"
    else
        echo "equals"
    fi
    networks["banana"]=1
done < temp_ips.txt

# SCRIPT
TC=/sbin/tc
INTERFACE=eth0
SPEED_LIMIT=100mbit;
IPSET_NAME=vpn_clients

U32="$TC filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32"

# Check if the ipset exists, if not - create it, if yes - clear it
if ! sudo ipset list $IPSET_NAME &>/dev/null; then
    echo "ipset '$IPSET_NAME' does not exist. Creating it now..."
    sudo ipset create $IPSET_NAME hash:ip
else
    echo "ipset '$IPSET_NAME' already exists. flushing..."
    sudo ipset flush $IPSET_NAME
fi

for ip in "${!networks[@]}"; do
    sudo ipset add $IPSET_NAME "$ip"
    echo "Added IP: $ip"
done

# Verify the IPs in the ipset
echo "IPs added to ipset $IPSET_NAME:"
sudo ipset list $IPSET_NAME

# Clear existing traffic control (tc) rules on the interface
$TC qdisc del dev $INTERFACE root

# Create a root qdisc (HTB) for traffic control
$TC qdisc add dev $INTERFACE root handle 1:0 htb default 30

# Initialize an iterator for the class IDs
id_counter=1

# Loop through each IP in the ipset and create a tc class for it
for ip in $(sudo ipset list $IPSET_NAME | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'); do
    # Generate a simple class ID using the iterator
    CLASS_ID="1:$id_counter"  # Simple incremental class ID

    # Create a class for the IP
    sudo tc class add dev $INTERFACE parent 1: classid $CLASS_ID htb rate $SPEED_LIMIT

    # Apply a filter to match traffic from that IP to the corresponding class
    $U32 match ip dst $ip flowid $CLASS_ID

    echo "Created class for IP: $ip with classid $CLASS_ID"

    # Increment the class ID counter for the next IP
    ((id_counter++))
done

# Verify the classes and filters
echo "Traffic control configuration:"
$TC -s qdisc show dev $INTERFACE
$TC -s class show dev $INTERFACE