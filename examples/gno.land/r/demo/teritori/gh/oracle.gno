package gh

import (
	"std"
	"strings"
	"time"

	"gno.land/p/demo/avl"
)

var (
	accounts       avl.Tree  // id -> Account
	lastUpdateTime time.Time // used by the bot to only upload the diff
	oracleAddr     std.Address
)

func OracleLastUpdated() time.Time { return lastUpdateTime }

func OracleUpsertAccount(id, login, name, kind string) {
	assertIsOracle()
	lastUpdateTime = time.Now()

	// get or create
	account := &Account{}
	res, ok := accounts.Get(id)
	if ok {
		account = res.(*Account)
	} else {
		account.id = id
	}

	// update fields
	account.name = name
	account.kind = kind
	account.login = login

	if err := account.Validate(); err != nil {
		panic(err)
	}

	// save
	accounts.Set(id, account)
}

func AdminSetOracleAddr(new std.Address) {
	assertIsAdmin()
	oracleAddr = new
}

func assertIsOracle() {
	if std.GetOrigCaller() != oracleAddr {
		panic("restricted area")
	}
}
