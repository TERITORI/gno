package gh

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
)

func TestLinkAccount(t *testing.T) {
	adminAddr = "g1test1234" 
	
	user := testutils.TestAddress("user")
	admin := testutils.TestAddress("admin")
	
	std.TestSetOrigCaller(admin)
	setAdminAddress(admin)
	AdminSetOracleAddr(admin)	

	OracleUpsertAccount("123","user", "user", UserAccount)
	LinkAccount("123", user, "signature")
	accountInPublic, ok := addressToAccount.Get(user.String())
	if !ok {
		t.Fatalf("account not found")
	}
	account := AccountByID("123")
	if accountInPublic != account {
		t.Fatalf("account is not same")
	}
}
