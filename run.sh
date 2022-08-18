#!/bin/bash

# include dependecies
root=$(dirname "$0")

source ${root}/boards/util.sh
source ${root}/src/debug.sh
source ${root}/src/system.sh
source ${root}/src/config.sh
source ${root}/src/util.sh
source ${root}/src/tests/tests.sh
source ${root}/src/tests/ethernet.sh
source ${root}/src/tests/ethernet-link.sh
source ${root}/src/tests/usb-gadget.sh
source ${root}/src/tests/pm.sh
source ${root}/src/tests/install-boot-imgs.sh
source ${root}/src/tests/reboot.sh
source ${root}/src/tests/qspi.sh

# global dictionary keeping board config
declare -A config=( )

# black hole
bh=/dev/null 2>&1

function validateArgs() {
	if [[ -z $board ]]; then
		return 0
	fi

	if [[ ! -z ${tst} ]]; then
		if isTestValid "${tst}"; then
			return 0
		fi
	fi

	if [[ ! -z ${rootfsPartition} ]] && [[ ! -d ${rootfsPartition} ]]; then
		return 0
	fi

	if [[ ! -z ${testImgDir} ]] && [[ ! -d ${testImgDir} ]]; then
		return 0
	fi

	return 1
}

function usage() {
	echo "usage: $1 [-b][-h]"
	echo
	echo -e "\tTest Linux4SAM binaries"
	echo
	echo -e "\t-b"
	echo -e "\t\tboard to run tests for"
	echo -e "\t-l"
	echo -e "\t\tlist all supported boards"
	echo -e "\t-i"
	echo -e "\t\tlist IPs supported for each board"
	echo -e "\t-t"
	echo -e "\t\trun only test"
	echo -e "\t-x"
	echo -e "\t\tlist all supported tests"
	echo -e "\t-p"
	echo -e "\t\texecute all teste after suspend to mem"
	echo -e "\t-c"
	echo -e "\t\t</path/to/rootfs/parition>"
	echo -e "\t-a"
	echo -e "\t\t</path/to/dirs/were/test/images/are/stored>"
	echo -e "\t-h"
	echo -e "\t\tdisplay this help message and exit"
	echo -e ""
}

if validateSystem; then
	tools=$(getSystemTools)
	printlog ${err} "Invalid system configuration! Check you have installed the following tools: ${tools}"
	exit 1
fi

board= tst= pm= rootfsPartition= testImgDir=
while getopts "b:lit:xpc:a:h" opt; do
	case $opt in
		b) board=$OPTARG ;;
		l) showBoards ; exit 0 ;;
		i) showBoardsIps ; exit 0 ;;
		t) tst=$OPTARG ;;
		x) showTests ; exit 0 ;;
		p) pm=y ;;
		c) rootfsPartition=$OPTARG ;;
		a) testImgDir=$OPTARG ;;
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

if updateConfig; then
	printlog ${err} "Failed to include board dependecies!"
	exit 1
fi

if validateConfig "$(declare -p config)"; then
	printlog ${err} "Invalid config!"
	exit 1
fi

# update session id
config["session-id"]=$(uuidgen)

# IP address parition prepare is executed to update the board IP address on
# the SD card that will be used later in the test procedure. One should run
# this script with -c </path/to/rootfs/parititon> in order to prepare SD
# card with IP addresses that are used by board config file.
if [[ ! -z ${rootfsPartition} ]]; then
	configIpAddressOnSDCardParition ${rootfsPartition} ${config["ip"]} "eth0"
	printlog ${info} "Done!"
	exit 0
fi

# Remove ssh keys
ssh-keygen -f "/home/$(whoami)/.ssh/known_hosts" -R ${config["ip"]}

# run tests
for idx in "${!globalTestsOrdered[@]}"; do
	testName=${globalTestsOrdered[${idx}]}
	if [ ! -z ${tst} ] && [ ${tst} != ${testName} ]; then
		continue
	fi

	printlog ${info} "Testing ${testName}... " y
	if ${globalTests[${testName}]} "$(declare -p config)"; then
		printlog ${err} "fail"
	else
		printlog ${info} "OK"
	fi
done

if [[ -z ${pm} ]]; then
	exit 0
fi

# run PM tests
printlog ${info} "Testing PM... " y
if pmTest "$(declare -p config)"; then
	printlog ${err} "Fail"
	exit 1
fi
printlog ${info} "OK"

# run all tests again
for idx in "${!globalTestsOrdered[@]}"; do
	testName=${globalTestsOrdered[${idx}]}

	if [ ${testName} == "install-boot-imgs" ]; then
		continue
	fi

	if [ ! -z ${tst} ] && [ ${tst} != ${testName} ]; then
		continue
	fi

	printlog ${info} "Testing ${testName}... " y
	if ${globalTests[${testName}]} "$(declare -p config)"; then
		printlog ${err} "fail"
	else
		printlog ${info} "OK"
	fi
done

exit 0
