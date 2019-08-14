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
# @$2:			block on execution
# @$3:			log everything to file (need to be cleared after execution)
# return:		command output
function runCmd() {
	local cmd=$1
	local blocking=$2
	local logtofile=$3

	if [ "${blocking}" == "y" ]; then
		if [ "${logtofile}" == "y" ]; then
			output=$(sshpass -f <(printf '%s\n' ${config["passwd"]}) ssh -o StrictHostKeyChecking=no root@${config["ip"]} ${cmd} > /tmp/${config["session-id"]}-${config["board"]}.log)
		else
			output=$(sshpass -f <(printf '%s\n' ${config["passwd"]}) ssh -o StrictHostKeyChecking=no root@${config["ip"]} ${cmd})
		fi
	else
		$(sshpass -f <(printf '%s\n' ${config["passwd"]}) ssh -f -o StrictHostKeyChecking=no root@${config["ip"]} ${cmd} < /dev/null > /tmp/${config["session-id"]}-${config["board"]}.log 2>&1 &)

		# give it a chance to start on remote system
		sleep 5
	fi

	echo "${output}"
}

