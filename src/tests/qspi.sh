#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

#set -x

# testEthernetLink: 	run ethernet link tests
# @args:		config
# return:		1 - success, 0 - fail
function testQspi() {
	eval "declare -A cfg="${1#*=}

	[[ $(runCmd "dmesg -c" "" y > /dev/null) ]] && return 0
	[[ $(runCmd "modprobe mtd_speedtest dev=0" 60 y > /dev/null) ]] && return 0
	[[ $(runCmd "rmmod mtd_speedtest" "" y > /dev/null) ]] && return 0
	[[ $(runCmd "dmesg -c" "" y > output) ]] && return 0

	pageWriteValue=$(cat output | grep "mtd_speedtest: page write speed is" | \
			 awk '{print $6}')
	pageWriteUnit=$(cat output | grep "mtd_speedtest: page write speed is" | \
			awk '{print $7}')

	pageReadValue=$(cat output | grep "mtd_speedtest: page read speed is" | \
			awk '{print $6}')
	pageReadUnit=$(cat output | grep "mtd_speedtest: page read speed is" | \
			awk '{print $7}')

	[[ ${pageWriteUnit} != ${cfg["qspi-page-write-unit"]} ]] && \
		echo "Invalid page write speed ${pageWriteValue} ${pageWriteUnit}" && \
		return 0
	[[ ${pageWriteValue} -lt ${cfg["qspi-page-write"]} ]] && \
		echo "Page write speed lt ${cfg["qspi-page-write"]}" && \
		return 0

	[[ ${pageReadUnit} != ${cfg["qspi-page-read-unit"]} ]] && \
		echo "Invalid page read speed ${pageReadValue} ${pageReadUnit}" && \
		return 0
	[[ ${pageReadValue} -lt ${cfg["qspi-page-read"]} ]] && \
		echo "Page read speed lt ${cfg["qspi-page-read"]}" && \
		return 0

	printlog ${info} "Page write: ${pageWriteValue} ${pageWriteUnit}"
	printlog ${info} "Page read:  ${pageReadValue} ${pageReadUnit}"

	return 1
}
