#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

# testUsbEhciCommunication:	test USB EHCI communication
# @args:			config
# return:			1 - success, 0 - fail
function testUsbEhciCommunication() {
	eval "declare -A cfg="${1#*=}
	local cnt=0

	while [ ${cnt} -lt ${cfg["usb-hosts"]} ]; do
		runCmd " \
			mkdir -p /tmp/usb; \
			mount /dev/sda1 /tmp/usb; \
			cd /tmp/usb; \
			dd if=/dev/urandom of=my_test_file.bin bs=1024 count=2048; \
			mk5sum my_test_file.bin > test.md5; \
			cd ; \
			umount usb; \
			" > ${bh}
		[[ $? -ne 0 ]] && return 0

		read -p "Remove mass storage USB device in host ${cnt}. Press any key when ready..." \
			-n 1 -r

		out=$(runCmd " \
			      mount /dev/sda1 /tmp/usb; \
			      cd /tmp/usb; \
			      md5sum -c test.md5")

		ok=$(echo "${out}" | grep ": OK")
		[[ -z ${out} ]] && return 0

		cnt=$((cnt+1))
	done

	# all good
	return 1
}
