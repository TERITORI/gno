package tori20

import (
	"std"
	"strings"

	"gno.land/p/demo/grc/grc20"
	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/users"
)

var (
	tori   *grc20.AdminToken
	admin std.Address = "g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj" // TODO: helper to change admin
)

func init() {
	tori = grc20.NewAdminToken("tori", "tori", 4)
	tori.Mint(admin, 1000000*10000)                                    // @administrator (1M)
	tori.Mint("g1u7y667z64x2h7vc6fmpcprgey4ck233jaww9zq", 10000*10000) // @manfred (10k)
}

// method proxies as public functions.
//

// getters.

func TotalSupply() uint64 {
	return tori.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	balance, err := tori.BalanceOf(owner.Resolve())
	if err != nil {
		panic(err)
	}
	return balance
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	allowance, err := tori.Allowance(owner.Resolve(), spender.Resolve())
	if err != nil {
		panic(err)
	}
	return allowance
}

// setters.

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	err := tori.Transfer(caller, to.Resolve(), amount)
	if err != nil {
		panic(err)
	}
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	err := tori.Approve(caller, spender.Resolve(), amount)
	if err != nil {
		panic(err)
	}
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	err := tori.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
	if err != nil {
		panic(err)
	}
}

// faucet.

func Faucet() {
	// FIXME: add limits?
	// FIXME: add payment in gnot?
	caller := std.PrevRealm().Addr()
	err := tori.Mint(caller, 1000*10000) // 1k
	if err != nil {
		panic(err)
	}
}

// administration.

func Mint(address users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	assertIsAdmin(caller)
	err := tori.Mint(address.Resolve(), amount)
	if err != nil {
		panic(err)
	}
}

func Burn(address users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	assertIsAdmin(caller)
	err := tori.Burn(address.Resolve(), amount)
	if err != nil {
		panic(err)
	}
}

// render.
//

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return tori.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance, _ := tori.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d\n", balance)
	default:
		return "404\n"
	}
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}
