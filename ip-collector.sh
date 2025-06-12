#!/bin/bash
NETWORKS_FILE=networks.txt
LOGS_FILE_PATH="/var/log/xray-connections.log"

# Array to hold the IP groups by network
declare -A networks
declare last_network

# Check if .log file exists
if ! test -e $LOGS_FILE_PATH; then
    echo ".log file not found"
    exit
fi

# Check and read existing networks file to an array
if [ -e "$NETWORKS_FILE" ]; then
    echo "Reading $NETWORKS_FILE"
    mapfile -t temp < "$NETWORKS_FILE"
    for network in "${temp[@]}"; do
        networks["$network"]=0
    done
    echo "Found ${#networks[@]} ip in $NETWORKS_FILE"
fi

# Grep ips from logs
echo "Reading xray logs..."

# Extract unique client IPs (only IPv4, without ports)
mapfile -t ips < <(awk '{print $5}' $LOGS_FILE_PATH | grep -oP '(?<=::ffff:)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=\])' | sort -u)

echo "Found ${#ips[@]} unique IP(s) in logs."

# Optional: print them
for ip in "${ips[@]}"; do
  echo "$ip"
done

# Initialize counter for new and skipped ip and iterate through logs
new_ip_counter=0;
skipped_ip_counter=0;
echo "Converting ip to network"
for ip in "${ips[@]}"; do
        
    # Convert ip from 192.168.1.1 to 192.168.0.0/16
    current_network=$(echo "$ip" | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]*\.[0-9]*/\1.0.0\/16/')

    # Check if ip exists and add to array
    if [[ -v networks["$current_network"] ]]; then
        ((skipped_ip_counter++))
        continue
    else
        networks["$current_network"]=0
        ((new_ip_counter++))
    fi
done

# Overwriting networks file
> $NETWORKS_FILE
for ip in "${!networks[@]}"; do
    echo "$ip" >> $NETWORKS_FILE 
done

echo "$new_ip_counter new networks have been added to the $NETWORKS_FILE"
echo "$skipped_ip_counter networks were skipped"