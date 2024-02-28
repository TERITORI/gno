package token_registry

import (
	"std"

	"gno.land/r/demo/users"
)

type Registry struct {
	registered []TokenInfo
	manager    string
}

func New(manager string) *Registry {
	r := Registry{
		registered: []TokenInfo{},
		manager:    manager,
	}
	return &r
}

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

func (r Registry) findToken(token string) (int, bool) {
	for i, pair := range r.registered {
		if pair.token == token {
			return i, true
		}
	}

	return -1, false
}

func (r Registry) appendGRC20Interface(pkgPath string, igrc20 GRC20Interface) {
	r.registered = append(r.registered, TokenInfo{isBank: false, token: pkgPath, igrc20: igrc20})
}

func (r Registry) appendBankToken(denom string) {
	r.registered = append(r.registered, TokenInfo{isBank: true, token: denom})
}

func (r Registry) removeToken(token string) {
	i, found := r.findToken(token)
	if !found {
		return
	}

	r.registered = append(r.registered[:i], r.registered[i+1:]...)
}

func (r Registry) RegisterGRC20Interface(token string, igrc20 GRC20Interface) {
	_, found := r.findToken(token)
	if found {
		panic("GRC20 already registered")
	}

	r.appendGRC20Interface(token, igrc20)
}

func (r Registry) UnregisterToken(token string) {
	// do not allow realm to unregister
	std.AssertOriginCall()
	caller := std.GetOrigCaller()

	if caller != r.manager {
		panic("unauthorized")
	}

	_, found := r.findToken(token)
	if found {
		r.removeToken(token)
	}
}

func (r Registry) RegisterBankToken(denom string) {
	_, found := r.findToken(denom)
	if found {
		panic("Token already registered")
	}

	r.appendBankToken(denom)
}

func (r Registry) RealmAddr() string {
	realmAddr := std.GetOrigPkgAddr()
	return realmAddr.String()
}

func (r Registry) TransferByInterfaceName(token string, to std.Address, amount uint64) bool {
	i, found := r.findToken(token)
	if !found {
		return false
	}

	if r.registered[i].isBank {
		banker := std.GetBanker(std.BankerTypeRealmSend)

		coin := std.Coins{{token, int64(amount)}}
		realmAddr := std.GetOrigPkgAddr()

		// Send coin from realm
		banker.SendCoins(realmAddr, to, coin)
		return true
	}
	r.registered[i].igrc20.Transfer()(users.AddressOrName(to), amount)

	return true
}

func (r Registry) TransferFromByInterfaceName(token string, from, to std.Address, amount uint64) bool {
	i, found := r.findToken(token)
	if !found {
		return false
	}

	if r.registered[i].isBank {
		coinSent := std.GetOrigSend() // get Coins sent with call
		caller := std.GetOrigCaller() // get tx sender

		if len(coinSent) != 1 {
			panic("only one coin can be sent")
		}

		if int64(amount) != coinSent.AmountOf(r.registered[i].token) {
			panic("invalid amount sent")
		}

		if caller.String() != from {
			panic("only caller should be configured for banker TransferFrom")
		}

		realmAddr := std.GetOrigPkgAddr()
		if to.String() != realmAddr.String() {
			// Send coin from realm to target
			banker := std.GetBanker(std.BankerTypeOrigSend)
			coin := std.Coins{{token, int64(amount)}}
			banker.SendCoins(realmAddr, to, coin)
		}
		return true
	}
	r.registered[i].igrc20.TransferFrom()(users.AddressOrName(from), users.AddressOrName(to), amount)

	return true
}

func (r Registry) BalanceOfByInterfaceName(token string, owner std.Address) uint64 {
	i, found := r.findToken(token)
	if !found {
		return 0
	}

	if r.registered[i].isBank {
		banker := std.GetBanker(std.BankerTypeReadonly)
		coins := banker.GetCoins(owner)
		for _, coin := range coins {
			if coin.Denom == token {
				return uint64(coin.Amount)
			}
		}
		return 0
	}
	balance := r.registered[i].igrc20.BalanceOf()(users.AddressOrName(owner))
	return balance
}
