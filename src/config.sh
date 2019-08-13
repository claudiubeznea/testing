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

