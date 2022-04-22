#!/bin/bash
timeout=10
screenshot_directory=/tmp

function yesno {
  question=$1
  
  zenity --question --text "$question" --width=300 --timeout=$timeout 2> /dev/null
}

mate-screenshot -ac

file="$screenshot_directory/Screenshots/$(date +%F@%T).png

if yesno "Save screenshot as $file?"; then
  xclip -selection clipboard -t image/png -o > $file
fi
