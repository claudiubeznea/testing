#!/bin/bash

root=$(dirname "$0")

source ${root}/src/util.sh

# testEthernet: 	run ethernet test
# @args:		config
# return:		1 - success, 0 - fail
function testEthernet() {
	eval "declare -A cfg="${1#*=}

	# sanity
	[[ $(checkPing ${cfg["ip"]}) ]] && return 0

	# RX
	[[ $(runCmd "iperf3 -s > /tmp/out" 1 > ${bh}) ]] && return 0
	[[ $(iperf3 -c ${cfg["ip"]} > ${bh}) ]] && return 0

	# stop the server
	pid=$(runCmd "ps -ef | grep -m 1 iperf3 | awk '{print \$1}'" "" y)
	runCmd "kill -9 ${pid}" > ${bh}

	# get results
	out=$(runCmd "cat /tmp/out")
	rxBw=$(echo "${out}" | grep "receiver" | awk '{print $7}')
	rxBwUnit=$(echo "${out}" | grep "receiver" | awk '{print $8}')
	printlog ${info} "RX: ${rxBw} ${rxBwUnit} " y

	# TX
	[[ $(iperf3 -s > ${bh} &) ]] && return 0
	[[ $(runCmd "iperf3 -c ${cfg["host-ip"]} > /tmp/out" > ${bh}) ]] && return 0

	# stop the server
	pid=$(ps -ef | grep -m 1 iperf3 | awk '{print $2}')
	[[ $(kill -9 ${pid} > ${bh}) ]] && return 0

	# get results
	out=$(runCmd "cat /tmp/out")
	txBw=$(echo "${out}" | grep "sender" | awk '{print $7}')
	txBwUnit=$(echo "${out}" | grep "sender" | awk '{print $8}')
	printlog ${info} "TX: ${txBw} ${txBwUnit}"

	# TX/RX
	[[ $(runCmd "iperf3 -s > /tmp/out-server &" 1 > ${bh}) ]] && return 0
	[[ $(iperf3 -s > ${bh} &) ]] && return 0

	[[ $(runCmd "iperf3 -c ${cfg["host-ip"]} -O 5 -t 60 > /tmp/out &" > ${bh}) ]] && return 0
	[[ $(iperf3 -c ${cfg["ip"]} -O 5 -t 60 > ${bh} &) ]] && return 0

	timeOut 70 verbose

	out=$(runCmd "cat /tmp/out")
	txBw=$(echo "${out}" | grep -m 1 "sender" | awk '{print $7}')
	txBwUnit=$(echo "${out}" | grep -m 1 "sender" | awk '{print $8}')

	out=$(runCmd "cat /tmp/out-server")
	rxBw=$(echo "${out}" | grep -m 1 "receiver" | awk '{print $7}')
	rxBwUnit=$(echo "${out}" | grep -m 1 "receiver" | awk '{print $8}')

	printlog ${info} "RX/TX: ${rxBw} ${rxBwUnit} / ${txBw} ${txBwUnit}"

	pid=$(ps -ef | grep -m 1 iperf3 | awk '{print $2}')
	[[ $(kill -9 ${pid} > ${bh}) ]] && return 0
	pid=$(runCmd "ps -ef | grep -m 1 iperf3 | awk '{print \$1}'" "" y)
	runCmd "kill -9 ${pid}" > ${bh}

	return 1
}
