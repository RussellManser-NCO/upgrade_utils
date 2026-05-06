#! /usr/bin/env bash
#####
# Purpose:
# How much has changed compared to current Prod:
# This script takes two arguments, the paths of the old and new code
# Outputs:
# (A)dded Files, (R)emoved Files, (M)odifiled Files
# 
#####
# Usage:
# $ this_code.sh -x fix -x .mod  path/to/prod/package path/to/para/package
# 
# In the above example, prod vs para is compared and fix and .mod files are excluded
#####

# Environmental variables:
# $TMP: temporary file directory; defaults to /tmp
#####
# Written by Arash Bigdeli (Arash.bigdeli@noaa.gov) Aug 2024
#

#Defaults
TMP=${TMP:-$(pwd)}
uniq=output.$(basename "$0")$(date +%s.%N)$$
tmpbase=$TMP/$uniq
declare -a exclArr
exclArr=( .git .git*  .svn  __pycache__ *.o *.def *.mod *.log *.stamp *.make *.camke exec rocoto dev docs fix  )

# read extra options 

while [ -n "$1" ]; do
case "$1" in 
 -a) 
  additem=$2
  exclArr=( ${exlArr[@]/$additem} )
  shift 1
  ;;
 -x) 
  exclitem=$2
  exclArr+=("$exclitem")
  shift 1
  ;;
 -h|--h|--help|-help) echo ""
     echo "This script posts the difference between current production and new code"
     echo "--------------------------------------------------------"
     echo "--------------------------------------------------------"
     echo "Usage:"
     echo " $(basename "$0") path_to_old path_to_new"    
     echo " Outputs (M)odified (A)dded and (R)emoved files " 
     echo "--------------------------------------------------------"
     echo "--------------------------------------------------------"
     echo "Option:"
     echo "via -x exclude dirs/patterns from diff"
     echo "via -a inldude something that has been excluded by default"
     echo "example:"
     echo " $(basename "$0") -a fix -x sorc -x .mk path_to_old path_to_new"
     echo "--------------------------------------------------------"
     echo "--------------------------------------------------------"
     echo "Defaults:" 
     echo "TMP: Output dir is set to PWD"
     echo 
     echo "The following are excluded from diff"
     echo " ${exclArr[@]}  " 
     exit 
  ;;
 *) dir0=$1
    dir1=$2
    shift 1
 ;;
esac
shift 1
done


exclArr+=("${exclsize[@]}")
echo "=======================================================-"
echo exclude list  = ${exclArr[@]}
echo "=======================================================-"
path_to_exl=( "${exclArr[@]/#/-x }")

#echo olddir=$dir0
#echo newdir=$dir1
if [[ -d $dir0 && -d $dir1 ]]; then echo ""; else echo "This script takes atleast two arguments: olddir and newdir, could not find them, exiting"; exit; fi

echo "Hello world!"

diff_output=$(diff -rq ${path_to_exl[@]} $dir0 $dir1 | sort )

# Process the diff output
while IFS= read -r line; do
    if [[ $line == *"differ"* ]]; then
        # Modified files
        file=$(echo "$line" | sed 's/Files \(.*\) and .* differ/\1/')
        echo "M ${file#${dir0/}}"
    elif [[ $line == *"Only in"* ]]; then
        # Files that are only in one directory (Added or Removed)
        if [[ $line == *"$dir0"* ]]; then
            # Removed files
            file=$(echo "$line" | sed 's|Only in '"$dir0"'\(.*\): \(.*\)|\1/\2|')
            echo "R ${file#/}"
        else
            # Added files
            file=$(echo "$line" | sed 's|Only in '"$dir1"'\(.*\): \(.*\)|\1/\2|')
            echo "A ${file#/}"
        fi
    fi
done <<< "$diff_output"
