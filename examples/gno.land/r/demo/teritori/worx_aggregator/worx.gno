package worx_aggregator

import(
	"gno.land/p/demo/avl"
)

//interface WorxDataProvider {
//    Get(dataName string, addr std.Address) any
//    SupportedTypes() []string
//}

var admin std.Address
var dataProviders []WorxDataProvider
var dataTypeToDataProvider avl.Tree


func Get(dataType string, addr std.Address) []any {
    all := []any{}
    dataProviders :=  dataTypeToDataProvider.Get(dataType)
    if len(dataProviders) == 0 {
        panic("there is not dataprovider configured for that datatype")
    }
    for d := range dataProviders {
        all = append(all, d.Get(dataType, addr)...)
    }
    return all
}


func RegisterDataProvider(dp WorxDataProvider) {
    assertAdmin()
	for supp := range dp.SupportedTypes() {
        providers := dataTypeToDataProvider.Get(supp)
        providers = append(providers, dp)
        dataTypeToDataProvider.set(supp, providers)
    }
}

func assertAdmin(){
	if (std.PrevRealm().Addr() != admin) {
        panic("unathorized")
    }
}