package gh

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
)

// private key 023742D9CFA2824BCA670868E11B00125625F9AF735CA42D9305ADD030F84515
func TestLinkAccount(t *testing.T) {
	adminAddr = "g1test1234"

	user := testutils.TestAddress("user")
	admin := testutils.TestAddress("admin")

	std.TestSetOrigCaller(admin)
	setAdminAddress(admin)
	AdminSetOracleAddr(admin)
	SetGuardianPublicKey("E921E29BC2F358F60B5F4C31999355309C6CCEB38204D10117557A39B5F59762")

	OracleUpsertAccount("123", "user", "user", UserAccount)
	LinkAccount("123", user, "C78A534203008326ACA3C9D3D4338F81B9547002789B79CCAC3514784B780B078126B7AB705954C5CB36A5B171B97B0501EDE74BFDACE3D3096AA0D65B816007")
	accountInPublic, ok := addressToAccount.Get(user.String())
	if !ok {
		t.Fatalf("account not found")
	}
	account := AccountByID("123")
	if accountInPublic != account {
		t.Fatalf("account is not same")
	}
}
