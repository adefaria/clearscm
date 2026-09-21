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

logfile="$certdir/logs/$(basename $0).log"

rm -f $logfile

function log {
    echo $1 >> $logfile
} # log

log "Starting $0"

# Determine domain from environment variables passed by certbot
if [ -n "$CERTBOT_DOMAIN" ]; then
    domain="$CERTBOT_DOMAIN"
elif [ -n "$RENEWED_LINEAGE" ]; then
    domain=$(basename "$RENEWED_LINEAGE")
else
    log "Neither CERTBOT_DOMAIN nor RENEWED_LINEAGE is set!"
    exit 1
fi

log "Are we root?"
log "$(id)"

log "cp /etc/letsencrypt/live/$domain/privkey.pem     $certdir && chmod 400 $certdir/privkey.pem"
cp /etc/letsencrypt/live/$domain/privkey.pem          $certdir && chmod 400 $certdir/privkey.pem
log "cp /etc/letsencrypt/live/$domain/cert.pem        $certdir && chmod 400 $certdir/cert.pem"
cp /etc/letsencrypt/live/$domain/cert.pem             $certdir && chmod 400 $certdir/cert.pem
log "cp /etc/letsencrypt/live/$domain/chain.pem       $certdir && chmod 400 $certdir/chain.pem"
cp /etc/letsencrypt/live/$domain/chain.pem            $certdir && chmod 400 $certdir/chain.pem
log "cp /etc/letsencrypt/live/$domain/fullchain.pem   $certdir && chmod 400 $certdir/fullchain.pem"
cp /etc/letsencrypt/live/$domain/fullchain.pem        $certdir && chmod 400 $certdir/fullchain.pem

# In the past we had /usr/syno/etc/certficiate/ReverseProxy/*/*.pem symlink to $certdir/*.pem. But
# when we restart nginx in certbot_deploy, it removes the symlink and copies over the file. This means
# that the next time certs are renewed it will not work since the symlink is no longerr present. So
# we must copy these files into place. One complication is that there are multipl, UUID named directories
# under $synocerts, one for each reverse proxy and each has its own set of .pem files. $synocerts are
# NFS mounted from Jupiter
synocerts=/System/Certificates/synocerts
for reverseproxy in $synocerts/*; do
  log "Processing $reverseproxy"
  for pem in cert chain fullchain privkey; do
    log "Processing $pem"
    cp $certdir/$pem.pem $reverseproxy/$pem.pem
  done
done

# Copy certs to Synology system default and archive certificate locations on Jupiter
log "Copying certs to Synology system default and archive locations on Jupiter"
ssh root@jupiter "cp /volume1/System/Certificates/*.pem /usr/syno/etc/certificate/system/default/ && cp /volume1/System/Certificates/*.pem /usr/syno/etc/certificate/_archive/\$(cat /usr/syno/etc/certificate/_archive/DEFAULT)/"

log "Restarting nginx on Synology"

# At this point this is all we need to do. Set up for ssh pre-shared key such that
# root on your desktop can ssh into the Synology (jupiter) without a password.
#
# Note: On DSM 6.x systemctl may be called /usr/syno/sbin/synosystemctl
ssh root@jupiter systemctl restart nginx

log "Nginx restarted"
