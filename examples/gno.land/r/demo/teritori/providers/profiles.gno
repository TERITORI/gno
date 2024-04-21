package provider

import (
	"std"
	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/teritori/registry"
)

var profiles avl.Tree

func init() {
    registry.Register("profiles", RegisterHandler)
}


func Get(dataName string, addr std.Address) interface{} {
	if dataName != "profile"{
		panic("invalid dataname")
	}
	profile:=getProfile(addr)

	return profile.ToString()
}

func SupportedTypes() interface{}{
	return []interface{}{"profile"}
}

func UpsertProfile(field string, value string){
	caller := std.GetOrigCaller()
	profile := getProfile(caller)
	profile.SetField(field, value)
	profiles.Set(caller.String(), profile)
}


func getProfile(addr std.Address ) *Profile {
	profile, found:=profiles.Get(addr.String())
	if !found{
		return &Profile{}
	}

	return profile.(*Profile)
}

func RegisterHandler(functionName string, args ...interface{}) interface{} {
	switch functionName {
	case "get":
		if len(args) != 2{
			panic("invalid number of arguments")
		}
		dataname := args[0].(string)
		address := args[1].(std.Address)
		return Get(dataname,address)
	case "supportedTypes":
		if len(args) != 0{
			panic("invalid number of arguments")
		}
		dataname := args[0].(string)
		address := args[1].(std.Address)
		return SupportedTypes()
	default:
		panic("invalid function name")
	}
}