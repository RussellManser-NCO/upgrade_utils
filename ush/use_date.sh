#!/bin/bash
#####
# Purpose:
# This script is run in the root directory of a WCOSS code package. It greps
# for non-commented uses of the word "date" to help identify any date
# manipulations being made without production date utilities.
#####
# Usage:
# $ cd /path/to/mycode.v1.2.3 ; application_9.sh
# >  ecf/jthanks_send2web.ecf:23:export cyc=`date -u +%H`
# >  ecf/jthanks_00.ecf:21:date
# >  scripts/exthanks.sh.ecf:93:export runtime=`date -u +"%a %b %d %H:%M:%S UTC %Y"`
# >  scripts/exthanks.sh.ecf:94:export rundate=`date -u +%Y%m%d%H%M%S`
#####
# Written by Alex Richert (alexander.richert@noaa.gov)
# Modified by A.Bigdeli Aug-2022 (arash.bigdeli@noaa.gov)
#

target_add=$1
pushd $target_add > /dev/null
for file in $(find ecf/ scripts/ ush/ -type f); do
 nocomment.sh $file | perl -pe 's|echo.*date||;s|^[[:space:]]*#.+||' | grep -nE "(\b|^)date(\b|$)" | perl -pe "s|^|$file:|g"
done
popd > /dev/null
