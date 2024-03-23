package gh

import (
	"fmt"
	"std"
	"gno.land/p/demo/avl"
)
var (
	addressToAccount avl.Tree    // address -> AccountLink
	guardian 	   std.Address // guardian address
) 

func init() {
	setAdminAddress(std.GetOrigCaller())
}

//Todo maybe we should gave multi guardian
func SetGuardian(address std.Address) {
	assertIsAdmin()
	guardian = address
}

func LinkAccount(accountID string, address std.Address, signature string) {
	verifySignature(fmt.Sprintf("%s %s", accountID, address.String()), signature)

	account := AccountByID(accountID)
	if account == nil {
		panic("account not found")
	}
	
	addressToAccount.Set(address.String(), account)
}

func verifySignature(message, signature string) bool {
	return true
}
