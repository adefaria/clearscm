#!/bin/bash
# This will set the audio system to be able to record both the mic and what
# is going on in the speakers. This might cause feedback to turn down the
# speakers. Also, you'll probably here an echo, ugh.
#
# 
module=$(pactl load-module module-loopback latency_msec=1)
echo "Note you must do pactl unload-module $module to turn this off"

