#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

# testReboot:		reboot target more than one time
# @args:		config
# return:		1 - success, 0 - fail
function testReboot() {
	eval "declare -A cfg="${1#*=}
	local cnt=1000

	while [ ${cnt} -gt 0 ]; do
		runCmd "reboot" "" y > /dev/null
		timeOut 50 ""
		printlog ${info} "${cnt} " y
		((cnt--))
	done

	return 1
}
