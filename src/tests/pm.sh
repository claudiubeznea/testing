#!/bin/bash

function pmTest() {
	eval "declare -A cfg="${1#*=}

	runCmd "echo +10 > /sys/class/rtc/rtc0/wakealarm; echo mem > /sys/power/state" ""

	# wait for wakeup
	sleep 20

	return 1
}
