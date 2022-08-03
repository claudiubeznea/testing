#!/bin/bash

root=$(dirname "$0")

source ${root}/src/util.sh

# testEthernet: 	run ethernet test
# @args:		config
# return:		1 - success, 0 - fail
function testEthernet() {
	eval "declare -A cfg="${1#*=}

	output=$(runCmd "ping -c 1 ${cfg["ip"]}" "" y> /dev/null 2>&1)
	if [ $? -ne 0 ]; then
		return 0
	fi

	# RX
	runCmd "iperf3 -s" 1 y >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(iperf3 -c ${cfg["ip"]} < /dev/null > /dev/null  2>&1)
	if [ $? -ne 0 ]; then
		return 0
	fi

	rxBw=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep "receiver" | awk '{print $7}')
	rxBwUnit=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep "receiver" | awk '{print $8}')

	printlog ${info} "RX: ${rxBw} ${rxBwUnit} " y
	runCmd "pkill -f iperf3" "" y > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(rm -rf /tmp/${cfg["session-id"]}-${cfg["board"]}.log)
	if [ $? -ne 0 ]; then
		return 0
	fi

	# TX
	$(iperf3 -s < /dev/null > /tmp/detached_local.log 2>&1 &)
	if [ $? -ne 0 ]; then
		return 0
	fi
	runCmd "iperf3 -c ${cfg["host-ip"]}" "" y y >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	txBw=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep "sender" | awk '{print $7}')
	txBwUnit=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep "sender" | awk '{print $8}')

	printlog ${info} "TX: ${txBw} ${txBwUnit} " y

	$(pkill iperf3 > /dev/null 2>&1)
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(rm -rf /tmp/${cfg["session-id"]}-${cfg["board"]}.log)
	if [ $? -ne 0 ]; then
		return 0
	fi

	# TX/RX
	runCmd "iperf3 -s" "" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi
	$(iperf3 -s < /dev/null > /tmp/${cfg["session-id"]}-${cfg["board"]}-server.log 2>&1 &)
	if [ $? -ne 0 ]; then
		return 0
	fi

	runCmd "iperf3 -c ${cfg["host-ip"]} -O 5 -t 60" "" y y >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi
	$(iperf3 -c ${cfg["ip"]} -O 5 -t 60 < /dev/null > /dev/null  2>&1)
	if [ $? -ne 0 ]; then
		return 0
	fi

	txBw=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep -m 1 "sender" | awk '{print $7}')
	txBwUnit=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep -m 1 "sender" | awk '{print $8}')
	rxBw=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep -m 1 "receiver" | awk '{print $7}')
	rxBwUnit=$(cat /tmp/${cfg["session-id"]}-${cfg["board"]}.log | grep -m 1 "receiver" | awk '{print $8}')

	printlog ${info} "TX/RX: ${txBw} ${txBwUnit} / ${rxBw} ${rxBwUnit} " y

	runCmd "pkill -f iperf3" "" y > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(pkill iperf3 > /dev/null 2>&1)
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(rm -rf /tmp/${cfg["session-id"]}-${cfg["board"]}.log)
	if [ $? -ne 0 ]; then
		return 0
	fi

	$(rm -rf /tmp/${cfg["session-id"]}-${cfg["board"]}-server.log)
	if [ $? -ne 0 ]; then
		return 0
	fi

	return 1
}
