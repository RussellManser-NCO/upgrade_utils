#!/usr/bin/env bash

#####
# Purpose:
# This script checks for hardcoded paths in specified directories (ush/, parm/, fix/) 
# and ensures they are removed, except in J-job and initialization files.
#
# Usage:
# $ ./check_hardcoded_paths.sh /path/to/package
#
# The script excludes:
# - J-job files (files starting with 'J' under 'jobs/')
# - Initialization files (common initialization scripts)
#
# Output:
# - Lists files containing hardcoded paths.
#####

# Define input package path
PACKAGE_DIR="$1"

# Ensure the package directory is provided
if [[ -z "$PACKAGE_DIR" ]]; then
    echo "Usage: $0 /path/to/package"
    exit 1
fi

# Directories to scan
TARGET_DIRS=("ush" "parm" "fix")

# Files to exclude (J-jobs, initialization scripts)
EXCLUDE_PATTERNS=("jobs/J*" "*/init*" "*/setup*" "*/config*")

# Patterns to search for (hardcoded paths)
PATH_PATTERNS=(
    "/usr/local"
    "/home"
    "/opt"
    "/lfs"
    "/mnt"
    "/scratch"
    "/data"
)

# Find files in target directories excluding J-jobs and initialization files
find_cmd="find $PACKAGE_DIR -type f"

# Add directory restrictions
for dir in "${TARGET_DIRS[@]}"; do
    find_cmd+=" \( -path \"$PACKAGE_DIR/$dir/*\" \)"
done

# Add exclusion patterns
for exclude in "${EXCLUDE_PATTERNS[@]}"; do
    find_cmd+=" -not -path \"$PACKAGE_DIR/$exclude\""
done

# Execute the find command and check for hardcoded paths
eval "$find_cmd" | while read -r file; do
    for path in "${PATH_PATTERNS[@]}"; do
        if grep -q "$path" "$file"; then
            echo "Hardcoded path found in: $file (Pattern: $path)"
        fi
    done
done

echo "Check complete."

