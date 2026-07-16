#!/bin/bash
#####
# Purpose:
# This script is run in the root directory of a WCOSS code package. It checks
# for GO TO statements and prints the total 
#####
# Usage:
# cd /path/to/mycode.v1.2.3 ; compiled_13.sh
# >  # of GOTO statements in ./sorc/mycode.fd/mycode.f: 0
# >  #####################################
# >  ==========
# >  ./sorc/build_mycode.sh
# >  22/26=84.6% of non-empty lines do not contain comments
# >  Longest uncommented block of code (# of non-empty lines): 22 (26)
# >  ==========
# >  ./sorc/mycode.fd/makefile
# >  22/40=55.0% of non-empty lines do not contain comments
# >  Longest uncommented block of code (# of non-empty lines): 10 (40)
# >  ==========
# >  ./sorc/mycode.fd/mycode.f
# >  246/444=55.4% of non-empty lines do not contain comments
# >  Longest uncommented block of code (# of non-empty lines): 19 (444)
#####
# Written by Alex Richert (alexander.richert@noaa.gov)
# Modified by A.Bigdeli Aug-2022 (arash.bigdeli@noaa.gov)
#
target_add=$1
pushd $target_add > /dev/null
array_goto=()
# GO TO:
for f in $(find ./* -type f | xargs file | grep FORTRAN | awk -F ':' '{print $1}'); do
 echo "# of GOTO statements in $f: $(nocomment.sh $f | grep -ciE '(\b|^)GO\ ?TO\b')"
 array_goto+=($(bc -l <<< $(nocomment.sh $f | grep -ciE '(\b|^)GO\ ?TO\b')))
done
echo '#####################################'
total_goto=$(dc <<< '[+]sa[z2!>az2!>b]sb'"${array_goto[*]}lbxp")
echo "Total GOTO statements found in target dir = ${total_goto}"

