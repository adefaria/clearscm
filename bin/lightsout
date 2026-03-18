#!/bin/bash
host=$(hostname)

if [ "$1" = "-a" ]; then
  if [ $host = "mars" ]; then
    setsid ssh earth lightsout.sh &
  elif [ $host = "earth" ]; then
    setsid ssh mars lightsout.sh &
  fi
fi

sleep 2
/usr/local/bin/setdpms.sh
xset dpms force off
