package registry

import (
	"gno.land/p/demo/avl"
	"std"
)

var callbacks avl.Tree
type FunctionCB func(functionName string, args ...interface{}) interface{}

func Register(id string, callback FunctionCB){
	_,exists:=callbacks.Get(id)
	if exists{
		panic("A callback already exists for the id")
	}

	callbacks.Set(id, callback)
}

func Exec(id string, functionName string, args ...interface{}) interface{} {
	cb, ok:= callbacks.Get(id)
	if !ok{
		panic("Callback not found")
	}
	function := cb.(FunctionCB)
	return function(functionName, args)
}