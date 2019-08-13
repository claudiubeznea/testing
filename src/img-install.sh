#!/bin/bash

# getBootDevice:	get current booting device
# @args:		none
# return:		booting device string
function getBootDevice() {
	local cmdline=$(runCmd "cat /proc/cmdline")
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

# installBootImgs:	install booting images (bootstrap, u-boot, itb)
# @$1:			booting device to install images on
# @$2:			session id
# @$3:			directory with booting images to install from
# @$4:			board name to install images for
# @$5:			IP address of the target where images are installed
# return:		1 - success, 0 - fail
function installBootImgs() {
	local device=$1
	local sessionId=$2
	local imgDir=$3
	local boardName=$4
	local ipAddr=$5
	local mountDir="${sessionId}-${device}"

	printlog ${info} "Instaling boot images..."
	runCmd "mkdir /mnt/${mountDir}" > /dev/null
	runCmd "mount /dev/${device} /mnt/${mountDir}" > /dev/null

	# copy
	sshpass -f <(printf '%s' root) scp ${imgDir}/BOOT.BIN root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/${boardName}.itb root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/u-boot.bin root@${ipAddr}:/mnt/${mountDir}
	sshpass -f <(printf '%s' root) scp ${imgDir}/uboot.env root@${ipAddr}:/mnt/${mountDir}
	
	runCmd "umount /mnt/${mountDir}" > /dev/null
	runCmd "rm -rf /mnt/${mountDir}" > /dev/null

	return 1
}

