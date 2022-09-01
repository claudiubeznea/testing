#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function getModeFor() {
	local for=$1
	local pm_mode=

	out=$(runCmd "dmesg | grep -i pm:")
	standby=$(echo "${out}" | awk '{print $4}')
	suspend=$(echo "${out}" | awk '{print $6}')
	if [ "${standby}" == "${for}," ]; then
		pm_mode=standby
	elif [ "${suspend}" == "${for}" ]; then
		pm_mode=mem
	fi

	printf "%s" ${pm_mode}
}

function runPMTest() {
	local pm_mode=$1
	local maxSuspends=3
	local wakeAlarm=5
	local linkUpTime=10
	local seconds=$((maxSuspends*(wakeAlarm+2)+linkUpTime))

	[[ $(runCmd "dmesg -c" > ${bh}) ]] && return 0

	disableVerbose

	$(runCmd " \
		cnt=${maxSuspends}; \
		while [ \${cnt} -gt 0 ]; do \
			echo +${wakeAlarm} > /sys/class/rtc/rtc0/wakealarm; \
			echo ${pm_mode} > /sys/power/state; \
			echo \$((cnt--)) > /dev/null; \
		done &")

	# timeout=cnt*(wakealarm+2)
	timeOut $(expr ${seconds}) verbose

	restoreVerbose

	out=$(runCmd "dmesg")
	count=$(echo "${out}" | grep "PM: suspend exit" | wc -l)
	[[ ${count} != ${maxSuspends} ]] && return 0

	return 1
}

# testStandbyContinuous:	run continuous suspend/resume procedures
# @args:			config
# return:			1 - success, 0 - fail
function testStandbyContinuous() {
	eval "declare -A cfg="${1#*=}

	pm_mode=$(getModeFor standby)
	[[ "${pm_mode}" == "" ]] && return 0

	rtc=$(runCmd "[[ -f /sys/class/rtc/rtc0/wakealarm ]] && echo 1")
	[[ -z ${rtc} ]] && return 0

	return $(runPMTest ${pm_mode})
}

# testULP0Continuous:		run continuous suspend/resume procedures on ULP0
# @args:			config
# return:			1 - success, 0 - fail
function testULP0Continuous() {
	eval "declare -A cfg="${1#*=}

	pm_mode=$(getModeFor ulp0)
	[[ "${pm_mode}" == "" ]] && return 0

	rtc=$(runCmd "[[ -f /sys/class/rtc/rtc0/wakealarm ]] && echo 1")
	[[ -z ${rtc} ]] && return 0

	return $(runPMTest ${pm_mode})
}

# testULP1Continuous:		run continuous suspend/resume procedures on ULP1
# @args:			config
# return:			1 - success, 0 - fail
function testULP1Continuous() {
	eval "declare -A cfg="${1#*=}

	pm_mode=$(getModeFor ulp1)
	[[ "${pm_mode}" == "" ]] && return 0

	rtc=$(runCmd "[[ -f /sys/class/rtc/rtc0/wakealarm ]] && echo 1")
	[[ -z ${rtc} ]] && return 0

	return $(runPMTest ${pm_mode})
}

# testBSRContinuous:		run continuous suspend/resume procedures on BSR
# @args:			config
# return:			1 - success, 0 - fail
function testBSRContinuous() {
	eval "declare -A cfg="${1#*=}

	pm_mode=$(getModeFor backup)
	[[ "${pm_mode}" == "" ]] && return 0

	rtc=$(runCmd "[[ -f /sys/class/rtc/rtc0/wakealarm ]] && echo 1")
	[[ -z ${rtc} ]] && return 0

	return $(runPMTest ${pm_mode})
}


# testBSRSelfRefresh:		test self-refresh on BSR
# @args:			config
# return:			1 - success, 0 - fail
function testBSRSelfRefresh() {
	eval "declare -A cfg="${1#*=}
	local maxSuspends=3
	local wakeAlarm=300
	local seconds=$((wakeAlarm+5))

	pm_mode=$(getModeFor backup)
	[[ "${pm_mode}" == "" ]] && return 0

	rtc=$(runCmd "[[ -f /sys/class/rtc/rtc0/wakealarm ]] && echo 1")
	[[ -z ${rtc} ]] && return 0

	# disable verbosity on console to reduce suspend/resume delays
	disableVerbose

	$(runCmd " \
		echo +300 > /sys/class/rtc/rtc0/wakealarm; \
		echo ${pm_mode} > /sys/power/state &")

	timeOut ${seconds} verbose

	# sanity
	[[ $(checkPing ${cfg["ip"]}) ]] && return 0

	runCmd "while [ true ]; do dmesg > /dev/null; done &" > ${bh}

	# wait another ~5' and check system is still responsive after that
	timeOut ${seconds} verbose

	[[ $(checkPing ${cfg["ip"]}) ]] && return 0

	killRemoteProcess "while \[ true \]; do dmesg > /dev/null; done"

	# restore verbosity
	restoreVerbose

	return 1
}
