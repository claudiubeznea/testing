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
source src/tests/install-boot-imgs.sh

declare -a boards=( "sama5d2_xplained" )

# global dictionary keeping board config
declare -A config=( )


function validateArgs() {
	if [[ -z $board ]]; then
		return 0
	fi

	if [[ ! -z "${tst}" ]]; then
		if isTestValid "${tst}"; then
			return 0
		fi
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
	echo -e "\t-t"
	echo -e "\t\trun only test"
	echo -e "\t-h"
	echo -e "\t\tdisplay this help message and exit"
	echo -e ""

}

if validateSystem; then
	tools=$(getSystemTools)
	printlog ${err} "Invalid system configuration! Check you have installed the following tools: ${tools}"
	exit 1
fi

board= tst=
while getopts "b:t:ph" opt; do
	case $opt in
		b) board=$OPTARG ;;
		t) tst=$OPTARG ;;
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

config["session-id"]=$(uuidgen)

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
fi

	exit 1
fi




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
