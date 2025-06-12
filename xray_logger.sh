#!/bin/bash

LOGFILE="/var/log/xray-connections.log"

  echo "==== $(date) ====" >> "$LOGFILE"
  ss -ntp | grep 'xray' >> "$LOGFILE"
  echo "" >> "$LOGFILE"
