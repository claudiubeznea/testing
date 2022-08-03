# test name - test function association
declare -A globalTests=(
	["install-boot-imgs"]=installBootImgs
	["ethernet-bw"]=testEthernet
	["ethernet-link"]=testEthernetLink
	["multiple-reboots"]=testReboot
	)

# test execution order
declare -a globalTestsOrdered=(
	# keep this first
	"install-boot-imgs"
	"ethernet-bw"
	"ethernet-link"
	"multiple-reboots"
	)

# isTestValid:		check if a test is valid
# @$1:			test to check if is valid or not
# returns:		0 - invalid test, 1 - valid test
function isTestValid() {
	local tst=$1

	for t in "${!globalTests[@]}"; do
		if [ ${t} == "${tst}" ]; then
			return 1
		fi
	done

	return 0
}

# showTests:		show supported tests
# @args:		none
# returns:		none
function showTests() {
	for idx in ${!globalTestsOrdered[@]}; do
		echo ${globalTestsOrdered[${idx}]}
	done
}
