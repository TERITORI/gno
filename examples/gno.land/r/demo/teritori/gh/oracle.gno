package gh

import (
	"std"
	"strings"
	"time"

	"gno.land/p/demo/avl"
)

var (
	accounts       avl.Tree    // uri -> Account
	lastUpdateTime time.Time   // used by the bot to only upload the diff
	oracleAddr     std.Address = "g1eunnckcl6r8ncwj0lrpxu9g5062xcvwxqlrf29"
	adminAddr      std.Address = "g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq" 
)

func OracleLastUpdated() time.Time { return lastUpdateTime }

func OracleUpsertAccount(id, name, kind string) {
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

func AdminGetOracleAddr() std.Address { return oracleAddr }

func assertIsAdmin() {
	if std.GetOrigCaller() != adminAddr {
		panic("restricted area")
	}
}

func assertIsOracle() {
	if std.GetOrigCaller() != oracleAddr {
		panic("restricted area")
	}
}