package worx_aggregator

import(
	"gno.land/p/demo/avl"
    "gno.land/r/demo/teritori/registry"
    "std"
)
var admin std.Address
var dataProviders []WorxDataProvider
var dataTypeToDataProvider avl.Tree


func Get(dataType string, addr std.Address) []any {
    all := []any{}
    dataProviders :=  dataTypeToDataProvider.Get(dataType)
    if len(dataProviders) == 0 {
        panic("there is not dataprovider configured for that datatype")
    }
    for registerID := range dataProviders {
        all = append(all, getFromRealm(registerID,dataType, addr)...)
    }
    return all
}


func RegisterDataProvider(registerRootID string) {
    assertAdmin()
    supportedTypes := registry.Exec(registerRootID, "supportedTypes")

    supportedTypesSlice := supportedTypes.[[]interface{}]
	for supp := range supportedTypesSlice {
        suppStr:= supp.(string)
        providers := dataTypeToDataProvider.Get(supp)
        providers = append(providers, registerRootID)
        dataTypeToDataProvider.set(supp, providers)
    }
}

func assertAdmin(){
	if (std.PrevRealm().Addr() != admin) {
        panic("unathorized")
    }
}

func getFromRealm(registerRootID string,dataType string, address std.Address) []any {
    getRegisterID := registerRootID 
    return registry.Exec(getRegisterID, "get", dataType, address)
}