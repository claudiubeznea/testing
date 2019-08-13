#!/bin/bash

# testUsbGadget:	test USB gadget
# @args:		none
# return:		none
function testUsbGadget() {
	runCmd "rmmod g_serial" > /dev/null
	runCmd "rmmod atmel_usba_udc" > /dev/null
	runCmd "modprobe atmel_usba_udc" > /dev/null
	runCmd "modprobe g_serial" > /dev/null

	recv=$(cat /dev/ttyACM0)
	runCmd "echo test > /dev/ttyGS0" > /dev/null

	recv=$(runCmd "cat /dev/ttyGS0")
	echo "test" > /dev/ttyACM0
}

