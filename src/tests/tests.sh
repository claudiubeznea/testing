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

