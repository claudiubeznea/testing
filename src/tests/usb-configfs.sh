#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testUsbConfigfsCleanup() {
	runCmd "echo \"\" > /sys/kernel/config/usb_gadget/g1/UDC" "" y ${BH}
	runCmd "rmmod atmel_usba_udc" "" y ${BH}
	runCmd "rmmod libcomposite" "" y ${BH}

	rm output

	return 1
}

# testUsbConfigfs:	test USB gadget
# @args:		config
# return:		1 - success, 0 - fail
function testUsbConfigfs() {
	eval "declare -A cfg="${1#*=}

	# prepare the field
	[[ $(runCmd "rmmod g_serial" "" y >/dev/null 2>&1) ]] && return 0
	[[ $(runCmd "rmmod atmel_usba_udc" "" y >/dev/null 2>&1) ]] && return 0
	
	# insert modules
	[[ $(runCmd "modprobe libcomposite" 10 y >/dev/null 2>&1) ]] && return 0
	[[ $(runCmd "modprobe atmel_usba_udc" 10 y >/dev/null 2>&1) ]] && return 0
	
	# and configure
	[[ $(runCmd "mount -t configfs none /sys/kernel/config" 10 y > /dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "mkdir /sys/kernel/config/usb_gadget/g1" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "cd /sys/kernel/config/usb_gadget/g1" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "echo \"0x1d6b\" > idVendor" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "echo \"0x0104\" > idProduct" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "mkdir strings/0x409" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "echo \"0123456789\" > strings/0x409/serialnumber" 10 y >/dev/null 2>&1) ]] && \
		return 0
			[[ $(runCmd "echo \"Foo Inc.\" > strings/0x409/manufacturer" 10 y >/dev/null 2>&1) ]] && \
		return 0
			[[ $(runCmd "echo \"Bar Gadget\" > strings/0x409/product" 10 y >/dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "mkdir functions/acm.GS0" 10 y > /dev/null 2>&1) ]] && \
		return 0
	[[ $(runCmd "mkdir configs/c.1" 10 y > /dev/null 2>&1) ]] && return 0
	[[ $(runCmd "mkdir configs/c.1/strings/0x409" 10 y > /dev/null 2>&1) ]] && return 0
	[[ $(runCmd "echo \"CDC ACM\" > configs/c.1/strings/0x409/configuration" \
		10 y > /dev/null 2>&1) ]] && return 0
	[[ $(runCmd "ln -s functions/acm.GS0 configs/c.1" 10 y > /dev/null 2>&1) ]] && \
		return 0

	# get gadget interface
	gadgetInterface=$(runCmd "ls /sys/class/udc" "" y)
	gadgetInterface=$(echo ${gadgetInterface} | awk '{print $1}')
	[[ $(runCmd "echo \"${gadgetInterface}\" > /sys/kernel/config/usb_gadget/g1/UDC" \
		10 y > /dev/null 2>&1) ]] && return 0

	# wait for /dev/ttyACM0 to be exported on localhost
	sleep 2

	# TX
	cat /dev/ttyACM0 > output &
	catPid=$!
	[[ "x${catPid}" == "x" ]] && ! testUsbConfigfsCleanup && return 0

	$(runCmd "echo test > /dev/ttyGS0" "" y)
	[[ ! $? ]] && [[ ! $(kill -9 ${catPid}) ]] && \
		! testUsbConfigfsCleanup && return 0
	
	# cleanup
	sync
	kill -9 ${catPid}

	# check result
	[[ "$(cat output)" != "test" ]] && ! testUsbConfigfsCleanup && return 0

	# RX
	runCmd "cat /dev/ttyGS0 > output" "" n y >/dev/null 2>&1
	[[ $? -ne 0 ]] && ! testUsbConfigfsCleanup && return 0

	echo "test" > /dev/ttyACM0
	[[ $? -ne 0 ]] && ! testUsbConfigfsCleanup && return 0

	# send Ctrl+c to kill cat
	runCmd "send -- \x03" "" y >/dev/null 2>&1

	output=$(runCmd "cat output" "" y)
	[[ "${output}" != "test" ]] && ! testUsbConfigfsCleanup && return 0

	# cleanup
	testUsbConfigfsCleanup
	
	# all good
	return 1
}
