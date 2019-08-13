#!/bin/bash

# testUsbGadget:	test USB gadget
# @args:		none
# return:		none
function testUsbGadget() {
	eval "declare -A cfg="${1#*=}

	runCmd "rmmod g_serial" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi
	runCmd "rmmod atmel_usba_udc" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi
	runCmd "modprobe atmel_usba_udc" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi
	runCmd "modprobe g_serial" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

#	recv=$(cat /dev/ttyACM0)
#	if [ $? -ne 0 ]; then
#		return 0
#	fi
: '
	runCmd "echo test > /dev/ttyGS0" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	recv=$(runCmd "cat /dev/ttyGS0") >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	echo "test" > /dev/ttyACM0
	if [ $? -ne 0 ]; then
		return 0
	fi
'
	return 1
}

