#!/bin/bash
. _DEBUG.sh

################################################################################
#
# File:         allmach
# Description:  Runs an arbitrary command on all machines
# Author:       Andrew@DeFaria.com
# Created:      Fri Apr 30 14:17:40 PDT 1999
# Language:     Bash Shell
# Modifications:Added trapping of INT so that you can abort a non-responding
#               machine.
#
# (c) Copyright 2001, Andrew@DeFaria.com, all rights reserved
#
################################################################################
# Set me to command name
me=$(basename $0)

if [ -f ~/.rc/set_colors ]; then
  source ~/.rc/set_colors
fi

# Set adm_base
adm_base=${adm_base:-/opt/clearscm}

# Set machines
machines=${machines:-$adm_base/data/machines}

if [ "$1" = "-f" ]; then
  shift
  machines="$1"
  shift
fi

if [ "$1" = "-r" ]; then
  root_ssh=true
  shift
fi

if [ ! -f $machines ]; then
  echo "Unable to find $machines file!"
  exit 1;
fi

function trap_intr {
  echo "${machines[i]}:$cmd interrupted"
  echo -e "$RED(A)bort$NORMAL $me or $YELLOW(C)ontinue$NORMAL with next machine? \c"
  read response
  typeset -l response=$response

  case "$response" in
    a|abort)
      echo "Aborting $me..."
      exit
    ;;
  esac
  echo "Continuing on with the next machine..."
} # trap_intr

# Build up data arrays. Note this is done because if we ssh while in a pipe
# Sun will not allow a simple ssh with no command (boo!)
# Column 1 Machine name
# Column 2 Model
# Column 3 OS Version
# Column 4 ClearCase Version (if applicable)
# Column 5 Owner (if known)
# Column 6 Usage (if known)
#oldIFS=$IFS
#IFS=":"
declare -i nbr_of_machines=0
#sed -e "/^#/d" $machines |
while read machine; do
  machines[nbr_of_machines]=$machine
  let nbr_of_machines=nbr_of_machines+1
done < <(grep -v ^# $machines)

if [[ -z "$@" ]]; then
  cmd="# ${YELLOW}<- ssh into machine$NORMAL"
else
  cmd="$@"
fi

# This loop executes the command
trap trap_intr INT
declare -i i=0
while [ $i -lt $nbr_of_machines ]; do
  export currmachine=${machines[i]}
  # Execute command. Note if no command is given then the effect is to
  # ssh to each machine.
  echo -e "${CYAN}${machines[i]}$NORMAL\c"
  echo -e ":$cmd"
  if [ $# -gt 0 ]; then
    if [ "$root_ssh" = "true" ]; then
      ssh ${machines[i]} -n -l root "$cmd"
    else
      ssh ${machines[i]} -n "$cmd"
    fi
  else
    if [ "$root_ssh" = "true" ]; then
      ssh ${machines[i]} -l root
    else
      ssh ${machines[i]}
    fi
  fi
  let i=i+1
done
trap - INT
