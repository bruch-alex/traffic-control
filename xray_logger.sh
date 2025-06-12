#!/bin/bash

LOGFILE="/var/log/xray-connections.log"

while true; do
  echo "==== $(date) ====" >> "$LOGFILE"
  ss -ntp | grep 'xray' >> "$LOGFILE"
  echo "" >> "$LOGFILE"
  sleep 5
done
