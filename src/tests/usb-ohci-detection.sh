#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testUsbOhciDetectionCleanup() {
	rm output
	
	return 1
}

# testUsbGadget:	test USB gadget
# @args:		config
# return:		1 - success, 0 - fail
function testUsbOhciDetection() {
	eval "declare -A cfg="${1#*=}
	local cnt=0

	while [ ${cnt} -lt ${cfg["usb-hosts"]} ]; do
		[[ $(runCmd "dmesg -c" "" y > ${bh}) ]] && return 0

		read -p "Insert USB mouse in host ${cnt}. Press any key when ready..." \
			-n 1 -r

		[[ $(runCmd "dmesg -c" "" y > output) ]] && return 0
		match=$(cat output | grep -i "low-speed USB")
		[[ -z "${match}" ]] && ! testUsbOhciDetectionCleanup && \
			return 0

		cnt=$((cnt+1))
	done

	# all good
	return 1
}
