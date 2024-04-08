package provider

import (
	"std"
	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
)

var profiles avl.Tree

func Get(dataName string, addr std.Address) string {
	if dataName != "profile"{
		panic("invalid dataname")
	}
	profile:=getProfile(addr)

	return profile.ToString()
}

func SupportedTypes() []string{
	return []string{"profile"}
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