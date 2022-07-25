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
# Crontab:      0 0 1 * * certbot renew --manual-auth-hook /path/to/certbot_authentication.sh --manual-cleanup-hook /path/to/certbot_cleanup.sh
#
# Author:       Andrew@DeFaria.com
# Created:      Fri 04 Jun 2021 11:20:16 PDT
# Modified:
# Language:     Bash
#
# (c) Copyright 2021, ClearSCM, Inc., all rights reserved
#
################################################################################
logfile="/tmp/$(basename $0).log"
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
    
    # We will try 4 times waiting 5 minutes in between
    max_attempts=4
    time_between_attempts=300 # 5 minutes (we might be able to shorten this)
    
    # Obviously it's not propagated immediately so first wait
    attempt=0
    while [ $attempt -lt 4 ]; do
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
# for importation to the Synology. /System/tmp is a directory that is
# on the Synology mounted via NFS.
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/privkey.pem /System/tmp && chmod 444 /System/tmp/privkey.pem
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/cert.pem    /System/tmp && chmod 444 /System/tmp/cert.pem
cp /etc/letsencrypt/live/$CERTBOT_DOMAIN/chain.pem   /System/tmp && chmod 444 /System/tmp/chain.pem

echo "Now go to DSM > Control Panel > Security > Certificate, select $CERTBOT_DOMAIN"
echo "then Add, Replace an existing certificate for *.$CERTBOT_DOMAIN, Import"
echo "Certificate and supply privkey.pem, cert.pem, and chain.pem for Private Key"
echo "Certificate, and Intermediate certificate."
