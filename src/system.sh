#!/bin/bash

declare -a systemTools=( "ssh" "sshpass" "uuidgen" "sleep" "grep" "mount" \
			 "umount" "mkdir" "scp" "ssh-keygen" )

function validateSystem() {
	for t in "${systemTools[@]}"; do
		which ${t} > /dev/null
		if [ $? -ne 0 ]; then
			return 0
		fi
	done
	
	return 1
}

# getSystemTools:	get the list of tools necessary for testing
# @args:		none
# return:		1 - success, 0 - fail
function getSystemTools() {
	local tools=

	for t in "${systemTools[@]}"; do
		tools="${tools} ${t}"
	done

	echo "${tools}"
}

