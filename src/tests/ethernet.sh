#!/bin/bash

source src/util.sh

function testEthernet() {
	runCmd "ping -c 1 ${config["ip"]}" > /dev/null
	if [ $? -ne 0 ]; then
		return 0
	fi

	return 1
}
