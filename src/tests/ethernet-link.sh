#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

# testEthernetLink: 	run ethernet link tests
# @args:		config
# return:		1 - success, 0 - fail
function testEthernetLink() {
	eval "declare -A cfg="${1#*=}
	local cnt=100

	while [ ${cnt} -gt 0 ]; do
		output=$(runCmd "ip link set eth0 down && sleep 5 && ip link set eth0 up && ping -c 1 ${cfg["ip"]}" 60 y)
		if [ $? -ne 0 ]; then
			return 0
		fi

		pingOk=$(echo ${output} | grep "0% packet loss")
		if [[ -z ${pingOk} ]]; then
			return 0
		fi

		((cnt--))
	done

	return 1
}
