#!/bin/bash
################################################################################
#
# File:         certbot_cleanup.sh
# Revision:     1.0
# Description:  Perform cleanup after domain validation by removing the TXT
#               record on the domain created by certbot_authentication.sh
#
#               Domain validation is the process of validating you have control
#               over a domain. Services like Let's Encrypt can then issue you
#               domain validated TLS certificates for use to secure websites.
#
# See also:     https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands
#
# Crontab:      0 0 20 Jan,Apr,Jul,Oct * certbot renew
#
# Author:       Andrew@DeFaria.com
# Created:      Fri 04 Jun 2021 11:20:16 PDT
# Modified:     Mon Oct 24 11:53:38 AM PDT 2022
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

# The following are environment variables that certbot passes to us
#
# CERTBOT_DOMAIN:     Domain being authenticated.
# CERTBOT_VALIDATION: Validation string for domain
#
# Check that CERTBOT_DOMAIN and CERTBOT_VALIDATION have been passed in properly
if [ -z "$CERTBOT_DOMAIN" ]; then
    log "CERTBOT_DOMAIN not passed in!"
    exit 1
else
    log "CERTBOT_DOMAIN = $CERTBOT_DOMAIN"
fi

if [ -z "$CERTBOT_VALIDATION" ]; then
    log "CERTBOT_VALIDATION not passed in!"
    exit 1
else
    log "CERTBOT_VALIDATION = $CERTBOT_VALIDATION"
fi

# My DNS registar is Dreamhost. These variables are specific to their DNS API.
# Yours will probably be different.
#
# Dreamhost key - generate at https://panel.dreamhost.com/?tree=home.api
key=KHY6UJQXD9MEJZHR

# URL where the REST endpoint is
url="https://api.dreamhost.com/?key=$key"

# Remove a TXT record. Oddly you must also specify the value.
function removeTXT {
    log "Removing TXT record $CERTBOT_DOMAIN = $CERTBOT_VALIDATION"
    cmd="$url&unique_id=$(uuidgen)&cmd=dns-remove_record&record=_acme-challenge.$CERTBOT_DOMAIN&type=TXT&value=$CERTBOT_VALIDATION"
    log "cmd: $cmd"

    response=$(wget -O- -q "$cmd")

    log "Response = $response"
    log "For some reason this has been reporting no_such_record"
    log "Check dreamhost.com to make sure it's removed"
} # removeTXT

removeTXT

# Removal is instanteous but propagation will take some time. No need to wait
# around though...

# Now deploy new certs
/opt/clearscm/bin/certbot_deploy.sh
