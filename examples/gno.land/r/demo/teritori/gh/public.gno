package gh
var (
addressesToAccount avl.Tree    // address -> AccountLink
adminAddr      std.Address = "g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq" 
) 
func LinkAccount(accountID string, address std.Address) {
	assertIsAdmin()
	account := AccountByID(id string)
	if account == nil {
		panic("account not found")
	}
	
	addressesToAccount.Set(address, account)
}

func assertIsAdmin() {
	if std.GetOrigCaller() != adminAddr {
		panic("restricted area")
	}
}