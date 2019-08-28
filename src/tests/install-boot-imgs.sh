#!/bin/bash

# getBootDevice:	get current booting device
# @args:		none
# return:		booting device string
function getBootDevice() {
	local cmdline=$(runCmd "cat /proc/cmdline" y)
	local device=

	echo "${cmdline}" | grep "mmc" > /dev/null
	if [ $? -eq 0 ]; then
		echo "${cmdline}" | grep "mmcblk0" > /dev/null
		if [ $? -eq 0 ]; then
			device=mmcblk0p1
		else
			device=mmcblk1p1
		fi
	fi

	echo "${device}"
}

# installBootImgs: 	run ethernet test
# @args:		config
# return:		1 - success, 0 - fail
function installBootImgs() {
	eval "declare -A cfg="${1#*=}
	local bootDevice=$(getBootDevice)
	local mountDir="${cfg["session-id"]}-${device}"

	if [[ -z ${bootDevice} ]]; then
		printlog ${err} "Failed to get boot device"
		return 0
	fi

	runCmd "mkdir /mnt/${mountDir}" y > /dev/null
	runCmd "mount /dev/${bootDevice} /mnt/${mountDir}" y > /dev/null

	# copy
	sshpass -f <(printf '%s' root) scp ${cfg["img-dir"]}/BOOT.BIN root@${cfg["ip"]}:/mnt/${mountDir} > /dev/null
	sshpass -f <(printf '%s' root) scp ${cfg["img-dir"]}/${cfg["board"]}.itb root@${cfg["ip"]}:/mnt/${mountDir} > /dev/null
	sshpass -f <(printf '%s' root) scp ${cfg["img-dir"]}/u-boot.bin root@${cfg["ip"]}:/mnt/${mountDir} > /dev/null
	sshpass -f <(printf '%s' root) scp ${cfg["img-dir"]}/uboot.env root@${cfg["ip"]}:/mnt/${mountDir} > /dev/null

	runCmd "umount /mnt/${mountDir}" y > /dev/null
	runCmd "rm -rf /mnt/${mountDir}" y > /dev/null

	printlog ${info} "Rebooting... "
	runCmd "reboot" y > /dev/null

	# Wait 1 minute for reboot. If more than 1 minute for reboot... something
	# is wrong with the new images
	timeout 60

	# Run a ls. If this doesn't work... something wrong
	runCmd "ls" y > /dev/null
	if [ $? -ne 0 ]; then
		return 0
	fi

	return 1
}

