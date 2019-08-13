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

