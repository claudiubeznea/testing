#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testUsbEhciDetectionCleanup() {
	rm output
	
	return 1
}

# testUsbGadget:	test USB EHCI detection
# @args:		config
# return:		1 - success, 0 - fail
function testUsbEhciDetection() {
	eval "declare -A cfg="${1#*=}
	local cnt=0

	while [ ${cnt} -lt ${cfg["usb-hosts"]} ]; do
		[[ $(runCmd "dmesg -c" "" y > ${bh}) ]] && return 0

		read -p "Insert USB mass storage device in host ${cnt}. Press any key when ready..." \
			-n 1 -r

		[[ $(runCmd "dmesg -c" "" y > output) ]] && return 0
		match=$(cat output | grep -i "high-speed USB")
		[[ -z "${match}" ]] && ! testUsbEhciDetectionCleanup && \
			return 0

		cnt=$((cnt+1))
	done

	# all good
	return 1
}
