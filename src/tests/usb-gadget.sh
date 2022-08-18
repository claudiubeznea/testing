#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testUsbGadgetCleanup() {
	runCmd "rmmod g_serial" "" y >/dev/null 2>&1
	runCmd "rmmod atmel_usba_udc" "" y >/dev/null 2>&1

	#rm output

	return 1
}

# testUsbGadget:	test USB gadget
# @args:		config
# return:		1 - success, 0 - fail
function testUsbGadget() {
	eval "declare -A cfg="${1#*=}

	[[ $(runCmd "rmmod g_serial" "" y >/dev/null 2>&1) ]] && return 0
	[[ $(runCmd "rmmod atmel_usba_udc" "" y >/dev/null 2>&1) ]] && return 0
	[[ $(runCmd "modprobe atmel_usba_udc" 10 y >/dev/null 2>&1) ]] && return 0
	[[ $(runCmd "modprobe g_serial" 10 y >/dev/null 2>&1) ]] && return 0

	# wait for /dev/ttyACM0 to be exported on localhost
	sleep 2

	# TX
	cat /dev/ttyACM0 > output &
	catPid=$!
	[[ "x${catPid}" == "x" ]] && ! testUsbGadgetCleanup && return 0

	$(runCmd "echo test > /dev/ttyGS0" "" y)
	[[ ! $? ]] && [[ ! $(kill -9 ${catPid}) ]] && \
		! testUsbGadgetCleanup && return 0

	# cleanup
	sync
	kill -9 ${catPid}

	# check result
	[[ "$(cat output)" != "test" ]] && ! testUsbGadgetCleanup && return 0

	# RX
	runCmd "cat /dev/ttyGS0 > output" "" n y >/dev/null 2>&1
	[[ $? -ne 0 ]] && ! testUsbGadgetCleanup && return 0

	echo "test" > /dev/ttyACM0
	[[ $? -ne 0 ]] && ! testUsbGadgetCleanup && return 0

	# send ctrl+c to kill cat
	runCmd "send -- \x03" "" y >/dev/null 2>&1

	output=$(runCmd "cat output" "" y)
	[[ "${output}" != "test" ]] && ! testUsbGadgetCleanup && return 0

	# cleanup
	testUsbGadgetCleanup

	# all good
	return 1
}
