#!/bin/bash

# timeOut:		count down a numer of seconds
# @$1:			number of seconds to count down
# return:		none
function timeOut() {
	local secs=$1
	local verbose=$2

	while [ ${secs} -gt 0 ]; do
		[ "x$verbose" != "x" ] && echo -en "\rWaiting ${secs} seconds..."
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
	local timeOut=3600
	local blocking=y
	local logtofile=n

	if [[ ! -z $2 ]]; then
		timeOut=$2
	fi

	if [[ ! -z $3 ]]; then
		blocking=y
	fi

	if [[ ! -z $4 ]]; then
		logtofile=y
	fi

	if [ "${blocking}" == "y" ]; then
		if [ "${logtofile}" == "y" ]; then
			output=$(sshpass -f <(printf '%s\n' ${config["passwd"]}) \
				timeout ${timeOut} ssh -o StrictHostKeyChecking=no \
				root@${config["ip"]} ${cmd} > \
				/tmp/${config["session-id"]}-${config["board"]}.log)
		else
			output=$(sshpass -f <(printf '%s\n' ${config["passwd"]}) \
				timeout ${timeOut} ssh -o StrictHostKeyChecking=no \
				root@${config["ip"]} ${cmd})
		fi
	else
		if [ "${logtofile}" == "y" ]; then
			$(sshpass -f <(printf '%s\n' ${config["passwd"]}) timeout \
			  ${timeOut} ssh -f -o StrictHostKeyChecking=no \
			  root@${config["ip"]} ${cmd} < /dev/null > \
			  /tmp/${config["session-id"]}-${config["board"]}.log 2>&1 &)
		else
			$(sshpass -f <(printf '%s\n' ${config["passwd"]}) timeout \
			  ${timeOut} ssh -f -o StrictHostKeyChecking=no \
			  root@${config["ip"]} ${cmd} < /dev/null > /dev/null 2>&1 &)
		fi

		# give it a chance to start on remote system
		sleep 5
	fi

	echo "${output}"
}

