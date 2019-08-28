# test name - test function association
declare -A globalTests=(
	["install-boot-imgs"]=installBootImgs
	["ethernet"]=testEthernet
	)

# test execution order
declare -a globalTestsOrdered=(
	# keep this first
	"install-boot-imgs"
	"ethernet"
	)

function isTestValid() {
	local tst=$1

	for t in "${!globalTests[@]}"; do
		if [ ${t} == "${tst}" ]; then
			return 1
		fi
	done

	return 0
}
