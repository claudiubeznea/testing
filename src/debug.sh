#!/bin/bash

# helpers for logging levels
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# logging levels
info=${GREEN}${BOLD}
warn=${YELLOW}${BOLD}
err=${RED}${BOLD}

# printlog:		print logs
# @$1:			logging level (info, warn, err)
# @$2:			message to be printed
# @$3:			if 'y' do not break the line that is printed
# return:		none
function printlog() {
	local logattrs=$1
	local msg=$2
	local n=$3
	local dislogattrs=""

	if [ ! -z ${logattrs} ]; then
		dislogattrs=${NC}
	fi

	if [ "${n}" = "y" ]; then
		echo -en "${logattrs}${msg}${dislogattrs}"
	else
		echo -e "${logattrs}${msg}${dislogattrs}"
	fi
}

