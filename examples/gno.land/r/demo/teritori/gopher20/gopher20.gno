package gopher20

import (
	"std"
	"strings"

	"gno.land/p/demo/grc/grc20"
	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/users"
)

var (
	gopher *grc20.AdminToken
	admin  std.Address = "g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt"
)

func init() {
	gopher = grc20.NewAdminToken("Gopher", "GOPHER", 4)
	gopher.Mint(admin, 1000000*10000) // @administrator (1M)
}

// method proxies as public functions.
//

// getters.

func TotalSupply() uint64 {
	return gopher.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	balance, err := gopher.BalanceOf(owner.Resolve())
	if err != nil {
		panic(err)
	}
	return balance
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	allowance, err := gopher.Allowance(owner.Resolve(), spender.Resolve())
	if err != nil {
		panic(err)
	}
	return allowance
}

// setters.
func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	gopher.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	gopher.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	gopher.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

// faucet.
func Faucet() {
	// FIXME: add limits?
	// FIXME: add payment in gnot?
	caller := std.PrevRealm().Addr()
	gopher.Mint(caller, 1000*10000) // 1k
}

// administration.
func Mint(address users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	assertIsAdmin(caller)
	gopher.Mint(address.Resolve(), amount)
}

func Burn(address users.AddressOrName, amount uint64) {
	caller := std.PrevRealm().Addr()
	assertIsAdmin(caller)
	gopher.Burn(address.Resolve(), amount)
}

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return gopher.RenderHome()
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance, _ := gopher.BalanceOf(owner.Resolve())
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
