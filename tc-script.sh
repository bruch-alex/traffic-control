#!/bin/bash

# SCRIPT
TC=/sbin/tc
INTERFACE=eth0

# Speeds
RATE_LIMIT=100mbit; # Guaranteed speed
CEIL_LIMIT=300mbit; # Maximum speed

#Other
IPSET_NAME=vpn_clients
NETWORKS_FILE=networks.txt

U32="$TC filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32"

# Check if the ipset exists, if not - create it, if yes - clear it
echo "Checking ipset"
if ! sudo ipset list $IPSET_NAME &>/dev/null; then
    echo "ipset '$IPSET_NAME' does not exist. Creating it now..."
    sudo ipset create $IPSET_NAME hash:net
else
    echo "ipset '$IPSET_NAME' already exists."
    sudo ipset flush $IPSET_NAME
fi

echo "Adding networks from $NETWORKS_FILE to $IPSET_NAME"
while IFS= read -r ip; do
    sudo ipset add $IPSET_NAME "$ip"
done < $NETWORKS_FILE

# Verify the IPs in the ipset
echo "All ip's in ipset $IPSET_NAME:"
sudo ipset list $IPSET_NAME

# Clear existing traffic control (tc) rules on the interface
$TC qdisc del dev $INTERFACE root

# Create a root qdisc (HTB) for traffic control
$TC qdisc add dev $INTERFACE root handle 1:0 htb default 50

# Initialize an iterator for the class IDs
id_counter=1

# Loop through each IP in the ipset and create a tc class for it
for ip in $(sudo ipset list $IPSET_NAME | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'); do
    # Generate a simple class ID using the iterator
    CLASS_ID="1:$id_counter"

    # Create a class for the IP
    sudo tc class add dev $INTERFACE parent 1: classid $CLASS_ID htb rate $RATE_LIMIT ceil $CEIL_LIMIT

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