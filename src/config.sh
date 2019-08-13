#!/bin/bash

# validateConfig:	validate board configuration
# @args:		none
# return:		1 - success, 0 - fail
function validateConfig() {
	# -z validation
	for c in "${config[@]}"; do
		if [[ -z ${c} ]]; then
			return 0
		fi
	done

	# individual validation
	if [[ ! -d ${config["img-dir"]} ]]; then
		return 0
	fi

	return 1
}

# updateConfig: 	update config dictionary with board config file
# @args:		none
# return:		1 - success, 0 - fail
function updateConfig() {
	if [ ! -f "board/config/${board}" ]; then
		return 0
	fi

	source "board/config/${board}"

	config["board"]=${BOARD_NAME}
	config["acm"]=${BOARD_ACM}
	config["ip"]=${BOARD_IP}
	config["passwd"]=${BOARD_PASSWD}
	config["img-dir"]=${BOARD_IMG_DIR}

	return 1
}

