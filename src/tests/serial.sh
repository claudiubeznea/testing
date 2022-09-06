#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testSerialCommunicationCleanup() {

	return 1
}

# testSerialCommunication:	test serial communication
# @args:			config
# return:			1 - success, 0 - fail
function testSerialCommunication() {
	eval "declare -A cfg="${1#*=}

	stty -F ${cfg["host-serial"]} 115200
	stty -F ${cfg["host-serial"]} -echo

	for serial in ${cfg["serials"]}; do
		[[ $(runCmd " \
			stty -F /dev/${serial} 115200; \
			stty -F /dev/${serial} -echo" ) ]] && return 0

		# TX
		cat ${cfg["host-serial"]} > output &
		catPid=$!

		[[ $(runCmd "echo test > /dev/${serial}" > ${bh}) ]] && \
			! testSerialCommunicationCleanup ${serial} && return 0

		# cleanup
		sync
		kill -9 ${catPid}
	
		# check result
		result=$(tr -d '\0\r' < output)
		[[ "${result}" != "test" ]] && \
			! testSerialCommunicationCleanup ${serial} && return 0

		# RX
		[[ $(runCmd "cat /dev/${serial} > /tmp/output &" > ${bh}) ]] && \
			return 0

		echo "test" > ${cfg["host-serial"]}

		[[ $(runCmd "sync") > ${bh} ]] && \
			! testSerialCommunicationCleanup ${serial} && return 0

		killRemoteProcess "cat /dev/${serial}"

		result=$(runCmd "tr -d \'\\0\\r\' < /tmp/output")
		[[ "${result}" != "test" ]] && \
			! testSerialCommunicationCleanup ${serial} && return 0
	done
	
	# all good
	return 1
}

function testSerialDMASize() {
	local size=$1
	local hostSerial=$2
	local targetSerialName=$3

	runCmd "cat /dev/${targetSerialName} > /tmp/output &" > ${bh}

	dd if=/dev/urandom of=${hostSerial} bs=1 count=${size} > ${bh}

	killRemoteProcess "cat /dev/${targetSerialName}"

	result=$(runCmd "hexdump -e '1/1 \"%02x\"\"\n\"' /tmp/output | wc -l")
	[[ $((result)) -ne $((size)) ]] && return 0

	return 1
}

function testSerialDMA() {
	eval "declare -A cfg="${1#*=}
	local index=0
	local hwAddrs=${cfg["serials-hw-addrs"]}

	stty -F ${cfg["host-serial"]} 115200 -cooked
	
	for serial in ${cfg["serials"]}; do
		output=$(runCmd "dmesg")
		result=$(echo ${output} | grep ${hwAddrs[${index}]} | \
			grep -i "dma transfers")
		[[ ${result} == "" ]] && echo "${serial} has no DMA configured" \
			&& continue

		runCmd "stty -F /dev/${serial} 115200 -cooked" > ${bh}

	 	if testSerialDMASize 2 ${cfg["host-serial"]} ${serial}; then
			return 0
		fi
		
		if testSerialDMASize 2047 ${cfg["host-serial"]} ${serial}; then
			return 0
		fi

		if testSerialDMASize 2048 ${cfg["host-serial"]} ${serial}; then
			return 0
		fi

		index=$((index+1))	
	done

	return 1
}
