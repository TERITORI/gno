package registry

import (
	"std"

	"gno.land/r/demo/users"
)

const APPROVED_UNREGISTER_CALLER = "g1sqt92sa06ugh8nlt98kyghw83qy84paf4csyh6"

var registered = []TokenInfo{}

type GRC20Interface interface {
	Transfer() func(to users.AddressOrName, amount uint64)
	TransferFrom() func(from, to users.AddressOrName, amount uint64)
	BalanceOf() func(owner users.AddressOrName) uint64
}

type TokenInfo struct {
	isBank bool
	token  string         // pkgPath (GRC20) | denom (Bank)
	igrc20 GRC20Interface // only valid when isBank is false
}

func findToken(token string) (int, bool) {
	for i, pair := range registered {
		if pair.token == token {
			return i, true
		}
	}

	return -1, false
}

func appendGRC20Interface(pkgPath string, igrc20 GRC20Interface) {
	registered = append(registered, TokenInfo{isBank: false, token: pkgPath, igrc20: igrc20})
}

func appendBankToken(denom string) {
	registered = append(registered, TokenInfo{isBank: true, token: denom})
}

func removeToken(token string) {
	i, found := findToken(token)
	if !found {
		return
	}

	registered = append(registered[:i], registered[i+1:]...)
}

func RegisterGRC20Interface(token string, igrc20 GRC20Interface) {
	_, found := findToken(token)
	if found {
		panic("GRC20 already registered")
	}

	appendGRC20Interface(token, igrc20)
}

func UnregisterToken(token string) {
	// do not allow realm to unregister
	std.AssertOriginCall()
	caller := std.GetOrigCaller()

	if caller != APPROVED_UNREGISTER_CALLER {
		panic("unauthorized")
	}

	_, found := findToken(token)
	if found {
		removeToken(token)
	}
}

func RegisterBankToken(denom string) {
	_, found := findToken(denom)
	if found {
		panic("Token already registered")
	}

	appendBankToken(denom)
}

func RealmAddr() string {
	realmAddr := std.GetOrigPkgAddr()
	return realmAddr.String()
}

func TransferByInterfaceName(token string, to std.Address, amount uint64) bool {
	i, found := findToken(token)
	if !found {
		return false
	}

	if registered[i].isBank {
		banker := std.GetBanker(std.BankerTypeRealmSend)

		coin := std.Coins{{token, int64(amount)}}
		realmAddr := std.GetOrigPkgAddr()

		// Send coin from realm
		banker.SendCoins(realmAddr, to, coin)
		return true
	}
	registered[i].igrc20.Transfer()(users.AddressOrName(to), amount)

	return true
}

func TransferFromByInterfaceName(token string, from, to std.Address, amount uint64) bool {
	i, found := findToken(token)
	if !found {
		return false
	}

	if registered[i].isBank {
		panic("TransferFrom's not enabled for native token")
	}
	registered[i].igrc20.TransferFrom()(users.AddressOrName(from), users.AddressOrName(to), amount)

	return true
}

func BalanceOfByInterfaceName(token string, owner std.Address) uint64 {
	i, found := findToken(token)
	if !found {
		return 0
	}

	if registered[i].isBank {
		banker := std.GetBanker(std.BankerTypeReadonly)
		coins := banker.GetCoins(owner)
		for _, coin := range coins {
			if coin.Denom == token {
				return uint64(coin.Amount)
			}
		}
		return 0
	}
	balance := registered[i].igrc20.BalanceOf()(users.AddressOrName(owner))
	return balance
}
