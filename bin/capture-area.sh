#!/bin/bash
#
# Apparently using png screws up sometimes so let's try using good old jpg
timeout=10
screenshot_directory=/tmp

function yesno {
  question=$1
  
  zenity --question --text "$question" --width=300 --timeout=$timeout 2> /dev/null
}

mate-screenshot --area --clipboard
aplay ~/Conf/CameraClick.wav

file="$screenshot_directory/$(date +%F@%T).jpg"

if yesno "Save screenshot as $file?"; then
  xclip -selection clipboard -t image/jpeg -o > $file
fi
