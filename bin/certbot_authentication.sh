#!/bin/bash
################################################################################
#
# File:         certbot_authentication.sh
# Revision:     1.0
# Description:  Perform domain validation by creating a TXT record on the domain
#               from certbot. This script is designed to work with
#               Dreamhost.com's API and certbot running on Ubuntu 20.04. Note
#               that it has not been extended to handle multiple domains.
#
#               Domain validation is the process of validating you have control
#               over a domain. Services like Let's Encrypt can then issue you
#               domain validated TLS certificates for use to secure websites.
#
# See also:     https://help.dreamhost.com/hc/en-us/articles/217555707-DNS-API-commands
#
# Crontab:      0 0 20 Jan,Apr,Jul,Oct * certbot renew
#
# Note:         If you symlink /etc/letsencrypt/renewal-hooks/{pre|post|deploy}
#               to the proper scripts then all you need is certbox renew. Also
#               if certbot doesn't think it's time to renew certs you can force it
#               with --force-renewal
#
# Author:       Andrew@DeFaria.com
# Created:      Fri 04 Jun 2021 11:20:16 PDT
# Modified:     Mon Oct 24 11:53:38 AM PDT 2022
# Language:     Bash
#
# (c) Copyright 2021, ClearSCM, Inc., all rights reserved
#
################################################################################
certdir=/System/Certificates

mkdir -p $certdir

logfile="$certdir/$(basename $0).log"

rm -f $logfile

function log {
    echo $1 >> $logfile
} # log

log "Starting $0"

# The following are environment variables that certbot passes to us
#
# CERTBOT_DOMAIN:     Domain being authenticated.
# CERTBOT_VALIDATION: Validation string for domain.
#
# Check that CERTBOT_DOMAIN and CERTBOT_VALIDATION have been passed in properly:
if [ -z "$CERTBOT_DOMAIN"]; then
    log "CERTBOT_DOMAIN not passed in!"
    exit 1
else
    log "CERTBOT_DOMAIN = $CERTBOT_DOMAIN"
fi

if [ -z "$CERTBOT_VALIDATION"]; then
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

# Add a TXT record to domain
function addTXT {
    log "Adding TXT record $CERTBOT_DOMAIN = $CERTBOT_VALIDATION"
    cmd="$url&unique_id=$(uuidgen)&cmd=dns-add_record&record=_acme-challenge.$CERTBOT_DOMAIN&type=TXT&value=$CERTBOT_VALIDATION"

    log "cmd = $cmd"

    response=$(wget -O- -q "$cmd")

    log "Response = $response"
} # addTXT

# Verifies that the TXT record has propogated.
function verifyPropagation {
    log "Enter verifyPropagation"

    # We will try 20 times waiting 1 minutes in between
    max_attempts=20
    time_between_attempts=60

    # Obviously it's not propagated immediately so first wait
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        log "Waiting $time_between_attempts seconds for TXT record $CERTBOT_DOMAIN to propagate..."
        sleep $time_between_attempts

        ((attempt++))
        log "Attempt #$attempt: Validating of propagation of TXT record $CERTBOT_DOMAIN"
        TXT=$(nslookup -type=TXT _acme-challenge.$CERTBOT_DOMAIN | grep -vi "can't find" | grep $CERTBOT_DOMAIN)

        if [ -n "$TXT" ]; then
            log "TXT record _acme-challenge.$CERTBOT_DOMAIN propagated"
            return
        else
            log "TXT record _acme-challenge.$CERTBOT_DOMAIN not propagated yet"
        fi
    done

    log "ERROR: Unable to validate propagation"
    exit 1
} # verifyPropagation

addTXT
verifyPropagation

# If we get here then new certs are produced but need to be made available
# for importation to the Synology. $certdir is a directory that is on the
# Synology mounted via NFS.
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/privkey.pem     $certdir && chmod 444 $certdir/privkey.pem
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/cert.pem        $certdir && chmod 444 $certdir/cert.pem
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/chain.pem       $certdir && chmod 444 $certdir/chain.pem
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/fullchain.pem   $certdir && chmod 444 $certdir/fullchain.pem
