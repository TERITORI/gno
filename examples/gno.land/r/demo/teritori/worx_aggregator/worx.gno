package worx_aggregator

import(
	"gno.land/p/demo/avl"
    "gno.land/p/demo/teritori/worx"
    "std"
)
var admin std.Address
var registeredProviders avl.Tree
var worxByAddress avl.Tree

func Push(hours int, metadata string, addr std.Address, points int, timestamp int64) {
    prevRealm := std.PrevRealm().Addr()
    dataProviders, ok := registeredProviders.Get(string(prevRealm))
    if !ok {
        panic("caller realm is not registered as provider")
    }
    keeper := getKeeper(addr)
    keeper.Store(worx.NewWorx(hours, metadata, addr, points, timestamp))
    worxByAddress.Set(string(addr), keeper)

    std.Emit("worx_added", 
        "addr",string(addr),
        "metadata", metadata,
    )
}

func getKeeper(addr std.Address) *worx.WorxKeeper{
    data, ok := worxByAddress.Get(string(addr))
    if ok {
        return data.(*worx.WorxKeeper)
    }
    return &worx.WorxKeeper{}
}

func Get(dataType string, addr std.Address) []*worx.Worx {
    return getKeeper(addr).Get()
}


func RegisterDataProvider(addr std.Address) {
    assertAdmin()
    _, ok :=registeredProviders.Get(string(addr))
    if !ok {
        panic("Data provider already registered")
    }
    registeredProviders.Set(string(addr), 0)
}

func assertAdmin(){
	if (std.PrevRealm().Addr() != admin) {
        panic("unathorized")
    }
}