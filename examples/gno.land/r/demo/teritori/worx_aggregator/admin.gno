package worx_aggregator

import (
	"std"
)

var adminAddr std.Address

func assertIsAdmin() {
	if std.PrevRealm().Addr() != adminAddr {
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
