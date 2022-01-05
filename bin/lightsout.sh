#!/bin/bash
host=$(hostname)

if [ "$1" = "-a" ]; then
  if [ $host = "mars" ]; then
    setsid ssh earth lightsout.sh &
  elif [ $host = "earth" ]; then
    setsid ssh mars lightsout.sh &
  fi
fi

if [ $host = "earth" ]; then
  export DISPLAY=:1
else
  export DISPLAY=:0
fi

sleep 2
/usr/local/bin/setdpms.sh
xset dpms force off
