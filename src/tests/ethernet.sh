#!/bin/bash

root=$(dirname "$0")

source ${root}/src/util.sh

# testEthernet: 	run ethernet test
# @args:		config
# return:		1 - success, 0 - fail
function testEthernetBw() {
	eval "declare -A cfg="${1#*=}

	# sanity
	[[ $(checkPing ${cfg["ip"]}) ]] && return 0

	# RX
	[[ $(runCmd "iperf3 -s > /tmp/out &" 1 > ${bh}) ]] && return 0
	iperf3 -c ${cfg["ip"]} > ${bh}

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
	[[ $(runCmd "iperf3 -s > /tmp/out-server &" > ${bh}) ]] && return 0
	[[ $(iperf3 -s > ${bh} &) ]] && return 0

	[[ $(runCmd "iperf3 -c ${cfg["host-ip"]} -O 5 -t 60 > /tmp/out &" > ${bh}) ]] && return 0
	[[ $(iperf3 -c ${cfg["ip"]} -O 5 -t 60 > ${bh} &) ]] && return 0

	timeOut 70 verbose

	# stop servers
	pid=$(ps -ef | grep -m 1 iperf3 | awk '{print $2}')
	[[ $(kill -9 ${pid} > ${bh}) ]] && return 0
	pid=$(runCmd "ps -ef | grep -m 1 iperf3 | awk '{print \$1}'" "" y)
	runCmd "kill -9 ${pid}" > ${bh}

	out=$(runCmd "cat /tmp/out")
	txBw=$(echo "${out}" | grep -m 1 "sender" | awk '{print $7}')
	txBwUnit=$(echo "${out}" | grep -m 1 "sender" | awk '{print $8}')

	out=$(runCmd "cat /tmp/out-server")
	rxBw=$(echo "${out}" | grep -m 1 "receiver" | awk '{print $7}')
	rxBwUnit=$(echo "${out}" | grep -m 1 "receiver" | awk '{print $8}')

	printlog ${info} "RX/TX: ${rxBw} ${rxBwUnit} / ${txBw} ${txBwUnit}"


	return 1
}

# testEthernetLink: 	run ethernet link tests
# @args:		config
# return:		1 - success, 0 - fail
function testEthernetLink() {
	eval "declare -A cfg="${1#*=}
	local cnt=100

	while [ ${cnt} -gt 0 ]; do
		output=$(runCmd "ip link set eth0 down && sleep 5 && ip link set eth0 up" 60 y)
		if [ $? -ne 0 ]; then
			return 0
		fi

		[[ $(checkPing ${cfg["ip"]}) ]] && return 0

		((cnt--))
	done

	return 1
}
