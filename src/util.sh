#!/bin/bash

# timeout:		count down a numer of seconds
# @$1:			number of seconds to count down
# return:		none
function timeout() {
	local secs=$1

	while [ ${secs} -gt 0 ]; do
		echo -en "\rWaiting ${secs} seconds..."
		secs=$((secs-1))

		sleep 1
	done

	echo ""
}

# runCmd:		execute a bash command on remote target
# @$1:			command to be executed
# return:		command output
function runCmd() {
	local cmd=$1

	output=$(sshpass -f <(printf '%s\n' ${config["passwd"]}) ssh -o StrictHostKeyChecking=no root@${config["ip"]} ${cmd})

	echo "${output}"
}

