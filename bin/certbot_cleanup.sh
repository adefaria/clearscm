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
# The following are environment variables that certbot passes to us
#
# CERTBOT_DOMAIN:     Domain being authenticated. For example,
#                     _acme-challenge.example.com for a wildcart cert or
#                     _acme-challenge.subdomain.example.com for a subdomain
#                     Note: Pass in $1 for testing or use the default of
#                     CERTBOT_DOMAIN
domain=${1:-CERTBOT_DOMAIN}

# CERTBOT_VALIDATION: The validation string. Pass in $2 or use the default of
#                     CERTBOT_VALIDATION
value=${2:-CERTBOT_VALIDATION}

logfile=/tmp/debug.log

function log {
  #echo $1
  echo $1 >> $logfile
} # log

# Dreamhost key - generate at https://panel.dreamhost.com/?tree=home.api 
key=KHY6UJQXD9MEJZHR

# URL where the REST endpoint is
url="https://api.dreamhost.com/?key=$key"

# Remove a TXT record. Oddly you must also specify the value.
function removeTXT {
  log "Removing TXT record $CERTBOT_DOMAIN = $CERTBOT_VALIDATION"
  cmd="$url&unique_id=$(uuidgen)&cmd=dns-remove_record&record=$CERTBOT_DOMAIN&type=TXT&value=$CERTBOT_VALIDATION"

  response=$(wget -O- -q "$cmd")

  log "$response"
} # removeTXT

removeTXT

# Removal is instanteous but propagation will take some time. No need to wait
# around though...