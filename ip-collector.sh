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

if [ -e "$NETWORKS_FILE" ]; then
    echo "Reading existing ip's from $NETWORKS_FILE"
    ip_from_file_counter=0
    while IFS= read -r ip; do
        networks["$ip"]=0
        ((ip_from_file_counter++))
    done < $NETWORKS_FILE
    echo "Found $ip_from_file_counter ip's in $NETWORKS_FILE"
fi

# Grep and process IPs
echo "Reading 3x-ui logs..."
mapfile -t ips < <(docker exec -it 3x-ui grep 'email:' $LOGS_FILE_PATH | grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)

# Initialize counter for new IP's
new_ip_counter=0;
skipped_ip_counter=0;
echo "Working with IP's..."
for ip in "${ips[@]}"; do
        
    # Convert ip from 192.168.1.1 to 192.168.0.0/16
    current_network=$(echo "$ip" | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]*\.[0-9]*/\1.0.0\/16/' | sed 's/ //g')

    # Check if it's null (or unset)
    if [[ -v networks["$current_network"] ]]; then
        #echo "$current_network exists, skipping..."
        continue
    else
        #echo "$current_network does not exist, adding ip."
        networks["$current_network"]=0
        echo "$current_network" >> $NETWORKS_FILE
        ((new_ip_counter++))
    fi
done

echo "$new_ip_counter new ip's have been added to the $NETWORKS_FILE"
echo "$skipped_ip_counter ip's were skipped"

#Delete duplicates
echo "Elemets before cleanup: $(wc -l $NETWORKS_FILE)"
echo "Starting cleanup"
sudo grep -Eo '([0-9]{1,3}\.){2}0\.0' $NETWORKS_FILE | sort -u > $NETWORKS_FILE.tmp && sudo mv $NETWORKS_FILE.tmp $NETWORKS_FILE
echo "Cleanup finished"
echo "Elemets after cleanup: $(wc -l $NETWORKS_FILE)"