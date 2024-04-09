package provider

import (
	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
)

type Profile struct{
	data avl.Tree
}

func(p *Profile) ToString() string{
	var data = ""
	p.data.Iterate("", "", func(key string, value interface{}) bool {
		data += ufmt.Sprintf("%s: %s\n",key, value)
		return false
	})
	return data
}

func(p *Profile) SetField(fieldName string, value string) {
	p.data.Set(fieldName, value)
}