#!/bin/bash

# timeOut:		count down a numer of seconds
# @$1:			number of seconds to count down
# return:		none
function timeOut() {
	local secs=$1
	local verbose=n

	if [[ ! -z $2 ]]; then
		verbose=y
	fi

	while [ ${secs} -gt 0 ]; do
		[ "$verbose" == "y" ] && echo -en "\rWaiting ${secs} seconds..."
		secs=$((secs-1))

		sleep 1
	done

	echo ""
}

function runCmd() {
	local cmd="$1"

	output=$(sshpass -p ${config["passwd"]} ssh -o StrictHostKeyChecking=no \
		 root@${config["ip"]} ${cmd})

	# give peace a chance
	sleep 1

	printf "%s" "${output}"
}

function checkPing() {
	local ip=$1

	output=$(runCmd "ping -c 1 ${ip}")
	pingOk=$(echo ${output} | grep -i "0% packet loss")
	[[ -z ${pingOk} ]] && return 0

	return 1
}

util_verbose=
function disableVerbose() {
	util_verbose=$(runCmd "cat /proc/sys/kernel/printk")
	runCmd "echo 1 1 1 1 > /proc/sys/kernel/printk"
}

function restoreVerbose() {
	runCmd "echo \"${util_verbose}\" > /proc/sys/kernel/printk"
}

function killRemoteProcess() {
	local processName="$1"

	pid=$(runCmd "ps | grep -m 1 \"${processName}\" | awk '{print \$1}'")
	runCmd "kill -9 ${pid}" > ${bh}
}

# tested w/ Ubuntu 2022.04
function killLocalProcess() {
	local processName="$1"

	pid=$(ps -ef | grep -m 1 "${processName}" | awk '{print $2}')
	kill -9 ${pid} > ${bh}
}
