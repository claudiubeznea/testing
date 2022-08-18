#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testUsbOhciCommunicationCleanup() {
	rm evDevs
	
	return 1
}

# testUsbGadget:	test USB gadget
# @args:		config
# return:		1 - success, 0 - fail
function testUsbOhciCommunication() {
	eval "declare -A cfg="${1#*=}
	local cnt=0
	local events

	while [ ${cnt} -lt ${cfg["usb-hosts"]} ]; do
		[[ $(runCmd "dmesg -c" "" y > ${bh}) ]] && return 0

		read -p "Insert USB mouse in host ${cnt}. Press any key when ready..." \
			-n 1 -r

		[[ $(runCmd "ls /dev/input/ | grep -i event" "" y > evDevs) ]] && \
			! testUsbOhciCommunicationCleanup && return 0
		[[ -z $(cat evDevs) ]] && ! testUsbOhciCommunicationCleanup && \
			return 0

		events=0
		trial=0
		pid=0
		for i in $(cat evDevs); do
			# try each event
			runCmd "evtest /dev/input/${i} > out &" "" n y > ${bh}
			[[ $? -ne 0 ]] && return 0

			pid=$(runCmd "ps -ef | grep -m 1 evtest | awk '{print \$1}'" "" y)

			read -p "Trial ${trial}: move the mouse. Press any key when done..." \
				-n 1 -r

			# kill evtest
			runCmd "kill -9 ${pid}" "" y > ${bh}

			# get the out
			out=$(runCmd "cat out" "" y)
			events=$(echo "${out}" | grep -i "Event:" | wc -l)
			[[ ${events} -gt 0 ]] && break
			trial=$((trial+1))
		done

		[[ ${events} -eq 0 ]] && ! testUsbOhciCommunicationCleanup && \
			return 0

		cnt=$((cnt+1))
	done

	# cleanup
	testUsbOhciCommunicationCleanup

	# all good
	return 1
}
