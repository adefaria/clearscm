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

# Dreamhost key - generate at https://panel.dreamhost.com/?tree=home.api
key=KHY6UJQXD9MEJZHR

# URL where the REST endpoint is
url="https://api.dreamhost.com/?key=$key"

# Add a TXT record to domain
function addTXT {
  echo "Adding TXT record $domain = $value)"
  cmd="$url&unique_id=$(uuidgen)&cmd=dns-add_record&record=$domain&type=TXT&value=$value"

  response=$(wget -O- -q "$cmd")

  echo "$response"
} # addTXT

# Verifies that the TXT record has propogated. Note that this cannot be
# likewise used for removal of the TXT record, which also needs to propagate.
# However, we are not concerned with when the removal is propagated, it can
# do so on its own time
function verifyPropagation {
  # We will try 4 times waiting 5 minutes in between
  max_attempts=4
  time_between_attempts=300

  # Obviously it's not propagated immediately so first wait
  attempt=0
  while [ $attempt -lt 4 ]; do
    echo "Waiting 5 minutes for TXT record $domain to propagate..."
    sleep $time_between_attempts

    ((attempt++))
    echo "Attempt #$attempt: Validating of propagation of TXT record $domain"
    TXT=$(nslookup -type=TXT $domain | grep -v "can't find" | grep $domain)

    if [ -n "$TXT" ]; then
      echo "TXT record $name.$domain propagated"
      return
    else
      echo "TXT record $name.$domain not propagated yet"
    fi
  done

  echo "ERROR: Unable to validate propagation"
  exit 1
} # verifyPropagation

addTXT
verifyPropagation
