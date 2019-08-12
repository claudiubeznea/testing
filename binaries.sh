#!/bin/bash

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info=${GREEN}${BOLD} 
warn=${YELLOW}${BOLD}
err=${RED}${BOLD}

declare -a systemTools=( "ssh" "sshpass" "uuidgen" "sleep" "grep" "mount" \
			 "umount" "mkdir" "scp" "ssh-keygen" )
declare -a boards=( "sama5d2_xplained" )

declare -A config=( ["board"]="sama5d2_xplained"
		    ["acm"]="/dev/ttyACM0"
		    ["ip"]="192.168.32.2"
		    ["password"]="root"
		    ["img-dir"]="/var/lib/tftpboot/tests/sama5d2_xplained/" )

function printlog() {
	local logattrs=$1
	local msg=$2
	local n=$3
	local dislogattrs=""

	if [ ! -z ${logattrs} ]; then
		dislogattrs=${NC}
	fi

	if [ "${n}" = "y" ]; then
		echo -en "${logattrs}${msg}${dislogattrs}"
	else
		echo -e "${logattrs}${msg}${dislogattrs}"
	fi		
}

function validateSystem() {
	for t in "${systemTools[@]}"; do
		which ${t} > /dev/null
		if [ $? -ne 0 ]; then
			return 0
		fi
	done
	
	return 1
}

function validateArgs() {
	
	return 1
}

function validateConfig() {
	if [[ -z ${config["board"]} ]]; then
		return 0
	fi

	if [[ -z ${config["acm"]} ]]; then
		return 0
	fi
	
	if [[ -z ${config["ip"]} ]]; then
		return 0
	fi

	if [[ -z ${config["password"]} ]]; then
		return 0
	fi
	
	if [[ -z ${config["img-dir"]} ]] || \
	   [[ ! -d ${config["img-dir"]} ]]; then
		return 0
	fi
	
	return 1
}

function listBoards() {
	for b in "${boards[@]}"; do
		echo ${b}
	done
}

function getBootDevice() {
	local cmdline=$(runCmd "cat /proc/cmdline")
	local device=

	echo "${cmdline}" | grep "mmc" > /dev/null
	if [ $? -eq 0 ]; then
		echo "${cmdline}" | grep "mmcblk0" > /dev/null
		if [ $? -eq 0 ]; then
			device=mmcblk0p1
		else
			device=mmcblk1p1
		fi
	fi

	echo "${device}"
}

function installBootImgs() {
	local device=$1
	local sessionId=$2
	local imgDir=$3
	local boardName=$4
	local ipAddr=$5
	local mountDir="${sessionId}-${device}"

	printlog ${info} "Instaling boot images..."
	runCmd "mkdir /mnt/${mountDir}" > /dev/null
	runCmd "mount /dev/${device} /mnt/${mountDir}" > /dev/null

	# copy
	sshpass -f <(printf '%s' root) scp ${imgDir}/BOOT.BIN root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/${boardName}.itb root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/u-boot.bin root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/uboot.env root@${ipAddr}:/mnt/${mountDir}
	
	runCmd "umount /mnt/${mountDir}" > /dev/null
	runCmd "rm -rf /mnt/${mountDir}" > /dev/null

	return 1
}

function runCmd() {
	local cmd=$1
	
	output=$(sshpass -f <(printf '%s\n' ${config["password"]}) ssh -o StrictHostKeyChecking=no root@${config["ip"]} ${cmd})
	
	echo "${output}"
}

function timeout() {
	local secs=$1
	local cmd=$2
	
	while [ ${secs} -gt 0 ]; do
		echo -en "\rWaiting ${secs} seconds..."
		secs=$((secs-1))
		#${cmd}
		#if [ $? -eq 0 ]; then
		#	break;
		#fi
		
		sleep 1
	done
	
	echo ""
}

function testUsbGadget() {
	runCmd "rmmod g_serial" > /dev/null
	runCmd "rmmod atmel_usba_udc" > /dev/null
	runCmd "modprobe atmel_usba_udc" > /dev/null
	runCmd "modprobe g_serial" > /dev/null
	
	recv=$(cat /dev/ttyACM0)
	runCmd "echo test > /dev/ttyGS0" > /dev/null
	
	recv=$(runCmd "cat /dev/ttyGS0")
	echo "test" > /dev/ttyACM0
	
}

function testEthernet() {
	runCmd "ping -c 1 ${config["ip"]}" > /dev/null
	if [ $? -ne 0 ]; then
		return 0
	fi
	
	return 1
}

function usage() {
	echo "usage: $1 [-p][-d][-h]"
	echo
	echo -e "\tTest AT91Bootstrap binaries"
	echo
	echo -e "\t-h"
	echo -e "\t\tdisplay this help message and exit"
	echo -e ""

}

imgDir=
while getopts "h" opt; do
	case $opt in
		h) usage $0; exit 0 ;;
		:) echo "missing argument for option -$OPTARG"; exit 1 ;;
		\?) echo "unknown option -$OPTARG"; exit 1 ;;
	esac                                                                        
done
shift $((OPTIND-1))

if validateArgs; then
	printlog ${err} "Invalid arguments. See -h!"
	exit 1
fi

if validateConfig; then
	printlog ${err} "Invalid config!"
	exit 1
fi

if validateSystem; then
	tools=
	for t in "${systemTools[@]}"; do
		tools="${tools} ${t}"
	done
	printlog ${err} "Invalid system configuration! Check you have installed the following tools: ${tools}"
	exit 1
fi

# Remove ssh keys
ssh-keygen -f "/home/$(whoami)/.ssh/known_hosts" -R ${config["ip"]}

sessionId=$(uuidgen)

bootDevice=$(getBootDevice)
if [[ -z ${bootDevice} ]]; then
	printlog ${err} "Failed to get boot device"
	exit 1
fi

if installBootImgs ${bootDevice} ${sessionId} ${imgDir} ${config["board"]} ${config["ip"]}; then
	printlog ${err} "Failed to install boot images"
	exit 1
fi

printlog ${info} "Rebooting..."
runCmd "reboot" > /dev/null

# Wait 1 minute for reboot. If more than 1 minute for reboot... something
# is wrong with the new images
timeout 60

# Run a ls. If this doesn't work... something wrong
runCmd "ls" > /dev/null
if [ $? -ne 0 ]; then
	printlog ${err} "fail!"
fi

printlog ${info} "Reboot OK"

printlog ${info} "Testing ethernet..." y
if testEthernet; then
	printlog ${err} "Fail"
else
	printlog ${info} "OK"
fi

exit 0