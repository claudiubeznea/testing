#!/bin/bash

# include dependecies
source src/debug.sh
source src/system.sh
source src/config.sh
source src/img-install.sh
source src/util.sh
source src/tests/tests.sh
source src/tests/ethernet.sh
source src/tests/usb-gadget.sh

declare -a boards=( "sama5d2_xplained" )

# global dictionary keeping board config
declare -A config=( )


function validateArgs() {
	if [[ -z $board ]]; then
		return 0
	fi
	
	return 1
}

function usage() {
	echo "usage: $1 [-b][-h]"
	echo
	echo -e "\tTest AT91Bootstrap binaries"
	echo
	echo -e "\t-b"
	echo -e "\t\tboard to run tests for"
	echo -e "\t-h"
	echo -e "\t\tdisplay this help message and exit"
	echo -e ""

}

if validateSystem; then
	tools=$(getSystemTools)
	printlog ${err} "Invalid system configuration! Check you have installed the following tools: ${tools}"
	exit 1
fi

board=
while getopts "b:h" opt; do
	case $opt in
		b) board=$OPTARG ;;
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

# Remove ssh keys
ssh-keygen -f "/home/$(whoami)/.ssh/known_hosts" -R ${config["ip"]}

sessionId=$(uuidgen)
config["session-id"]=$(uuidgen)

bootDevice=$(getBootDevice)
if [[ -z ${bootDevice} ]]; then
	printlog ${err} "Failed to get boot device"
	exit 1
fi

if installBootImgs ${bootDevice} ${sessionId} ${config["img-dir"]} ${config["board"]} ${config["ip"]}; then
	printlog ${err} "Failed to install boot images"
	exit 1
fi

printlog ${info} "Rebooting..."
runCmd "reboot" y > /dev/null

# Wait 1 minute for reboot. If more than 1 minute for reboot... something
# is wrong with the new images
timeout 60

# Run a ls. If this doesn't work... something wrong
runCmd "ls" y > /dev/null
if [ $? -ne 0 ]; then
	printlog ${err} "Reboot fail!"
fi

printlog ${info} "Reboot OK"

# run tests
for test in "${!globalTests[@]}"; do
	printlog ${info} "Testing ${test}... " y
	if ${globalTests[${test}]} "$(declare -p config)"; then
		printlog ${err} "fail"
	else
		printlog ${info} "OK"
	fi
done

exit 0
