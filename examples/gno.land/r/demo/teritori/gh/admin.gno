package gh

import (
	"std"
)

var(
	adminAddr      std.Address = "g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq" 
)


func assertIsAdmin() {
	if std.GetOrigCaller() != adminAddr {
		panic("restricted area")
	}
}

func setAdminAddress(address std.Address) {
	adminAddr = address
}

func SetAdminAddress(address std.Address) {
	assertIsAdmin()
	setAdminAddress(address)
}