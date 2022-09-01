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


}

