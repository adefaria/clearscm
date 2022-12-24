#!/bin/bash
################################################################################
#
# File:         certbot_deploy.sh
# Revision:     1.0
# Description:  Deploy the new certs. This script is run to deploy the new certs
#               onto the Synology. We should have already obtained new Let's
#               Encrypt certs and have placed them into /System/Certificates.
#               Now we just need to restart nginx on the Synology. This works
#               because /usr/syno/etc/certificate/_archive already has been
#               configured to look at /System/Certificates for new certs.
#
#               The restarting of nginx on Synology is large and takes time. You
#               will not be able to get into the DSM web page and Docker will
#               restart. Be patient and it should come back up with the new certs
#               active.
#
# See also:     https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands
#
# Crontab:      0 0 20 Jan,Apr,Jul,Oct * certbot renew
#
# Author:       Andrew@DeFaria.com
# Created:      Mon Oct 24 11:53:38 AM PDT 2022
# Modified:
# Language:     Bash
#
# (c) Copyright 2021, ClearSCM, Inc., all rights reserved
#
################################################################################
certdir="/System/Certificates"

mkdir -p $certdir

logfile="$certdir/$(basename $0).log"

rm -f $logfile

function log {
    echo $1 >> $logfile
} # log

log "Starting $0"
log "Restarting nginx on Synology"

# At this point this is all we need to do. Set up for ssh pre-shared key such that
# root on your desktop can ssh into the Synology (jupiter) without a password.
#
# Note: On DSM 6.x systemctl may be called /usr/syno/sbin/synosystemctl
ssh root@jupiter systemctl restart nginx

log "Nginx restarted"
