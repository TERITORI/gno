package random_pusher

import (
	"std"
	"gno.land/r/teritori/worx_aggregator"
	"math/rand"
)

var admin     std.Address

func init() {
    admin = std.GetOrigCaller()
	
}

var rSeed = rand.NewPCG(0, 0)

func RandWorx(addr std.Address){
	r := rand.New(rSeed)

	worx_aggregator.Push(r.IntN(25), "", addr, r.IntN(100), std.GetHeight())
}