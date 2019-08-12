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

