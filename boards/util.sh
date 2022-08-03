#!/bin/bash

root=$(dirname "$0")

# showBoards:		list the supported boards
# @args:		none
# return:		none
function showBoards() {
	for f in ${root}/boards/config/*; do
		boardName=$(basename ${f});
		echo ${boardName}
	done
}

function showBoardsIps() {
	echo -e "IP\t\tBoard Name"
	echo -e "------------\t----------"
	for f in ${root}/boards/config/*; do
		line=$(grep BOARD_IP ${f})
		boardName=$(basename ${f})
		IFS='=' read -ra lineTokenized <<< "${line}"
		echo -e "${lineTokenized[1]}\t${boardName}"
	done
}

# configIpAddressOnSDCardParition:	configure IP address on ROOTFS SD card
#					parition. This should be done before
#					inserting a new board in setup
# @$1:					path to rooftfs parition
# @$2:					IP address to be configured
# @$3:					Linux IP interface to work on
# returns:				0 - on failure, 1 - on success
function configIpAddressOnSDCardParition() {
	local rootfsPartition=$1
	local ip=$2
	local interface=$3

	if [ ! -f "${rootfsPartition}/etc/network/interfaces" ]; then
		return 0
	fi

	line="iface ${interface} inet dhcp"
	newLine="iface eth0 inet static\n\taddress ${ip}\n\tnetmask 255.255.255.0"

	echo "sed -i s/${line}/${newLine}/g ${rootfsPartition}/etc/network/interfaces "
	sed -i "s/${line}/${newLine}/g" "${rootfsPartition}/etc/network/interfaces"
	if [ $? -ne 0 ]; then
		return 0
	fi

	return 1
}
