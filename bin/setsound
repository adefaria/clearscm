#/bin/bash
# Need to set PULSE_RUNTIME_PATH under cron
export PULSE_RUNTIME_PATH=/run/user/$(id -u)/pulse
pactl -- set-sink-volume @DEFAULT_SINK@ $1%
