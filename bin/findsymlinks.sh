#!/bin/bash

path=$1

if [ -z "$path" ]; then
  echo "Usage $0 <path>"
  exit 1
fi

IFS='/' read -ra components <<< "$path"

testpath=''

for component in "${components[@]}"; do
  [ -z "$component" ] && continue

  testpath="${testpath}/$component"

  if [ -h "$testpath" ]; then
    points_to=$(ls -l $testpath | awk '{print $NF}')

    echo "$testpath: symbolic link to $(ls -l $testpath | awk '{print $NF}')"
    testpath=$(readlink -n $testpath)
  fi
done

