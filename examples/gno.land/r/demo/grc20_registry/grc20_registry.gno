package grc20_registry

import (
	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/grc/grc20"
)

var (
	registry = avl.NewTree() // addr -> IGRC20
	lol      grc20.IGRC20
)

func Register(token grc20.IGRC20) {
	caller := std.PrevRealm().Addr()
	// registry.Set(caller.String(), token)
	lol = token
}

func Get(addr std.Address) (grc20.IGRC20, bool) {
	coinI, ok := registry.Get(addr.String())
	if !ok {
		return nil, false
	}
	coin, ok := coinI.(grc20.IGRC20)
	if !ok {
		panic("should not happen")
	}
	return coin, true
}
