#!/bin/bash
ssh home "cd /opt/songbook && git pull && cd /opt/media && git pull"

# Removed Kent and Mikey so I need to rsync these
rsync -r /opt/songbook/Kent home:/opt/songbook
rsync -r /opt/songbook/Mikey home:/opt/songbook
