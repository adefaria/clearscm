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
# Crontab:      0 0 1 * * certbot renew --manual-aacmeuth-hook /path/to/certbot_authentication.sh --manual-cleanup-hook /path/to/certbot_cleanup.sh
#
# Author:       Andrew@DeFaria.com
# Created:      Fri 04 Jun 2021 11:20:16 PDT
# Modified:
# Language:     Bash
#
# (c) Copyright 2021, ClearSCM, Inc., all rights reserved
#
################################################################################
# The following are environment variables that certbot passes to us
#
# CERTBOT_DOMAIN:     Domain being authenticated. For example,
#                     _acme-challenge.example.com for a wildcart cert or
#                     _acme-challenge.subdomain.example.com for a subdomain
#                     Note: Pass in $1 for testing or use the default of
#                     CERTBOT_DOMAIN
domain=${1:-$CERTBOT_DOMAIN}

# CERTBOT_VALIDATION: The validation string. Pass in $2 or use the default of
#                     CERTBOT_VALIDATION
value=${2:-$CERTBOT_VALIDATION}

logfile=/tmp/debug.log
rm -f $logfile

function log {
  #echo $1
  echo $1 >> $logfile
} # log

log "domain = $domain"
log "value = $value"

# Dreamhost key - generate at https://panel.dreamhost.com/?tree=home.api
key=KHY6UJQXD9MEJZHR

# URL where the REST endpoint is
url="https://api.dreamhost.com/?key=$key"

# Add a TXT record to domain
function addTXT {
  log "Adding TXT record $domain = $value" >> $logfile
  cmd="$url&unique_id=$(uuidgen)&cmd=dns-add_record&record=&type=TXT&value=_acme-challenge.$domain=$value"

  log "cmd = $cmd" >> $logfile

  response=$(wget -O- -q "$cmd")

  log "Response = $response" >> $logfile
} # addTXT

# Verifies that the TXT record has propogated. Note that this cannot be
# likewise used for removal of the TXT record, which also needs to propagate.
# However, we are not concerned with when the removal is propagated, it can
# do so on its own time
function verifyPropagation {
  log "Enter verifyPropagation" >> $logfile
  # We will try 4 times waiting 5 minutes in between
  max_attempts=4
  time_between_attempts=300

  # Obviously it's not propagated immediately so first wait
  attempt=0
  while [ $attempt -lt 4 ]; do
    log "Waiting 5 minutes for TXT record $domain to propagate..." >> $logfile
    sleep $time_between_attempts

    ((attempt++))
    log "Attempt #$attempt: Validating of propagation of TXT record $domain" >> $logfile
    TXT=$(nslookup -type=TXT $domain | grep -vi "can't find" | grep $domain)

    if [ -n "$TXT" ]; then
      log "TXT record $name.$domain propagated" >> $logfile
      return
    else
      log "TXT record $name.$domain not propagated yet" >> $logfile
    fi
  done

  log "ERROR: Unable to validate propagation" >> $logfile
  exit 1
} # verifyPropagation

log "Calling addTXT" >> $logfile
addTXT
log "Returned from addTXT" >> $logfile
log "calling verifyPropagation" >> $logfile
verifyPropagation
log "Returned from verifyPropagation" >> $logfile
