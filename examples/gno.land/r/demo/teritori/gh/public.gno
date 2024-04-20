package gh

import (
	"crypto/ed25519"
	"encoding/hex"
	"std"

	"gno.land/p/demo/avl"
)

var (
	addressToAccount  avl.Tree // address -> Account
	guardianPublicKey string   // guardian public (maybe should an array)
)

func init() {
	addressToAccount = avl.Tree{}
	setAdminAddress(std.GetOrigCaller())
}

// Todo maybe we should gave multi guardian
func SetGuardianPublicKey(publicKey string) {
	assertIsAdmin()
	guardianPublicKey = publicKey
}

func LinkAccount(accountID string, address std.Address, signature string) {
	if !verifySignature(accountID, address, signature) {
		panic("signature verification failed")
	}

	account := AccountByID(accountID)
	if account == nil {
		panic("account not found")
	}

	addressToAccount.Set(address.String(), account)
}

func RenderAccount(address std.Address) string {
	account, ok := addressToAccount.Get(address.String())
	if !ok {
		panic("account not found")
	}

	return account.(*Account).Render()
}

func Render(address string) string {
	if address != "" {
		return RenderAccount(std.Address(address))
	}
	str := "["
	addressToAccount.Iterate("", "", func(key string, value interface{}) bool {
		account := value.(*Account)
		str += account.Render()
		str += ","
		return false
	})
	str += "]"

	return str
}

func verifySignature(accountID string, address std.Address, signature string) bool {
	publicKey, err := hex.DecodeString(guardianPublicKey)
	if err != nil {
		panic("invalid guardian public key")
	}

	sign, err := hex.DecodeString(signature)
	if err != nil {
		panic("invalid signature")
	}
	return ed25519.Verify(publicKey, []byte(accountID+" "+address.String()), sign)
}
