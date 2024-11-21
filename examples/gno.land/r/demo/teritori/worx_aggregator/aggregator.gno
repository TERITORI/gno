package worx_aggregator

import (
	"std"

	"gno.land/p/teritori/worx"
	"strings"

	"gno.land/p/demo/ufmt"
)

func GetWorx(addr std.Address) []*worx.Worx {
	keeper := getKeeper(addr)
	return keeper.Get()
}

func GetWorxFromDate(addr std.Address, date int64) []*worx.Worx {
	keeper := getKeeper(addr)
	return keeper.GetFromDate(date)
}

// Render renders the state of the realm
func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		res := "Registered Dataproviders \n"
		registeredProviders.Iterate("", "", func(key string, value interface{}) bool {	
			res += key + "\n"
			return false
		})

		return res
	case c == 1:
		// Render worx for this address
		owner := std.Address(parts[0])
		worxs := GetWorx(owner)
		res := "user Worxs:\n"
		for _, worx := range worxs {
			res += ufmt.Sprintf(" Hours %d, Points %d, Timestamp %d \n",worx.Hours, worx.Points, worx.Timestamp)
		}

		return res
	default:
		return "404\n"
	}
}