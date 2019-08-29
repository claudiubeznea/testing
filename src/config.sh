#!/bin/bash

# validateConfig:	validate board configuration
# @args:		none
# return:		1 - success, 0 - fail
function validateConfig() {
	eval "declare -A cfg="${1#*=}

	# -z validation
	for c in "${cfg[@]}"; do
		if [[ -z ${c} ]]; then
			return 0
		fi
	done

	# individual validation
	if [[ ! -d ${cfg["img-dir"]} ]]; then
		return 0
	fi

	return 1
}

# updateConfig: 	update config dictionary with board config file
# @args:		none
# note: 		call this in the context of run.sh
# return:		1 - success, 0 - fail
function updateConfig() {
	if [ ! -f "boards/config/${board}" ]; then
		return 0
	fi

	source "boards/config/${board}"

	config["board"]=${BOARD_NAME}
	config["acm"]=${BOARD_ACM}
	config["ip"]=${BOARD_IP}
	config["host-ip"]=${BOARD_HOST_IP}
	config["passwd"]=${BOARD_PASSWD}
	config["img-dir"]=${BOARD_IMG_DIR}

	return 1
}

