#!/bin/bash

source src/util.sh

# testEthernet: 	run ethernet test
# @args:		none
# return:		1 - success, 0 - fail
function testEthernet() {
	eval "declare -A cfg"=${1#*=}

	runCmd "ping -c 1 ${cfg["ip"]}" > /dev/null
	if [ $? -ne 0 ]; then
		return 0
	fi

	return 1
}
