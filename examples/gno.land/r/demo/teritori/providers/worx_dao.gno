package provider

import (
	"std"
	"gno.land/r/demo/teritori/worx_aggregator"
	"gno.land/p/demo/rand"
)

var admin     std.Address

func init() {
    admin = std.GetOrigCaller()
}

func RandWorx(addr std.Address){
	r := rand.New()
	worx_aggregator.Push(r.Intn(25), "", addr, r.Intn(100), std.GetHeight())
}