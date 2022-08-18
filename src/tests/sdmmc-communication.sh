#!/bin/bash

root=$(dirname "$0")
source ${root}/src/util.sh

function testSDMMCCommunicationCleanup() {
	runCmd "rm -rf /sdmmc" > ${bh}

	return 1
}

# testSDMMCGadget:	test SDMMC communication
# @args:		config
# return:		1 - success, 0 - fail
function testSDMMCCommunication() {
	eval "declare -A cfg="${1#*=}
	local cnt=0

	[[ $(runCmd " \
		     mkdir -p /sdmmc; \
		     dd if=/dev/urandom of=/sdmmc/my_test_file.bin bs=1024 \
			count=2048 > /dev/null 2>&1; \
		     md5sum /sdmmc/my_test_file.bin > /sdmmc/test.md5; \
		     reboot" > ${bh}) ]] && return 0

	timeOut 50 verbose

	out=$(runCmd "md5sum -c /sdmmc/test.md5")
	ok=$(echo "${out}" | grep ": OK")
	[[ -z ${out} ]] && return 0

	# cleanup
	testSDMMCCommunicationCleanup

	# all good
	return 1
}
