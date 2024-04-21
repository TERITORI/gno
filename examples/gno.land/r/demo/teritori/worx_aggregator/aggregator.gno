package worx_aggregator

import (
	"std"

	"gno.land/p/demo/teritori/worx"
)

func GetWorx(addr std.Address) []*worx.Worx {
	keeper := getKeeper(addr)
	return keeper.Get()
}

func GetWorxFromDate(addr std.Address, date int64) []*worx.Worx {
	keeper := getKeeper(addr)
	return keeper.GetFromDate(date)
}
