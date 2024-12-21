#!/bin/bash
NETWORKS_FILE=networks.txt
CONTAINER="3x-ui"
LOGS_FILE_PATH="access.log"

# Array to hold the IP groups by network
declare -A networks
declare last_network

# Check if .log file exists
if ! docker exec $CONTAINER test -e $LOGS_FILE_PATH; then
    echo ".log file not found"
    echo "U need to enable logs in 3x-ui webpanel"
    exit
fi

# Check and read existing networks file to an array
if [ -e "$NETWORKS_FILE" ]; then
    echo "Reading $NETWORKS_FILE"
    mapfile -t temp < "$NETWORKS_FILE"
    for ip in "${temp[@]}"; do
        networks["$ip"]=0
    done
    echo "Found ${#networks[@]} ip in $NETWORKS_FILE"
fi

# Grep ip from logs
echo "Reading 3x-ui logs..."
mapfile -t ips < <(docker exec -it 3x-ui grep 'email:' $LOGS_FILE_PATH | grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
echo "Found ${#ips[@]} ip in 3x-ui logs"

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