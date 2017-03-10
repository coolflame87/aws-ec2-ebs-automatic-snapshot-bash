#!/bin/bash
export PATH=$PATH:/usr/local/bin/:/usr/bin

# Safety feature: exit script if error is returned, or if variables not set.
# Exit if a pipeline results in an error.
set -ue
set -o pipefail

## Automatic S3 Sync Script
# Syncs directories and S3 prefixes. 
# Recursively copies new and updated files from the source directory to the destination. 
# Only creates folders in the destination if they contain one or more files.
# The sync command has the following form. Possible source-target combinations are:
# Local file system to Amazon S3
# Amazon S3 to local file system
# Amazon S3 to Amazon S3
#
# DISCLAIMER: This script deletes snapshots (though only the ones that it creates). 
# Make sure that you understand how the script works. No responsibility accepted in event of accidental data loss.
#

## Function Declarations ##

# Function: Confirm that the AWS CLI and related tools are installed.
prerequisite_check() {
	for prerequisite in aws date; do
		hash $prerequisite &> /dev/null
		if [[ $? == 1 ]]; then
			echo "In order to use this script, the executable \"$prerequisite\" must be installed." 1>&2; exit 70
		fi
	done
}

# Function: Setup logfile and redirect stdout/stderr.
log_setup() {
    # Check if logfile exists and is writable.
    ( [ -e "$logfile" ] || touch "$logfile" ) && [ ! -w "$logfile" ] && echo "ERROR: Cannot write to $logfile. Check permissions or sudo access." && exit 1

    tmplog=$(tail -n $logfile_max_lines $logfile 2>/dev/null) && echo "${tmplog}" > $logfile
    exec > >(tee -a $logfile)
    exec 2>&1
}

# Function: Log an event.
log() {
    echo "[$(date +"%Y-%m-%d"+"%T")]: $*"
}

# Function: Sync Source Path with Destination.
s3_sync() {
		log "sync $source_path with $destination_path "
	 	aws s3 sync $source_path $destination_path
}

#calls pre-requisite check function to ensure that all executables required for script execution are available
prerequisite_check

## Variable Declartions ##

# Local file system path or s3://bucket/
source_path="./"
# Local file system path or s3://bucket/
destination_path="s3://bucket/"

# Set Logging Options
logfile="/var/log/s3-sync.log"
logfile_max_lines="5000"

## SCRIPT COMMANDS ##

log_setup

s3_sync