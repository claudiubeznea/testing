#!/bin/bash

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info=${GREEN}${BOLD}
warn=${YELLOW}${BOLD}
err=${RED}${BOLD}

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

