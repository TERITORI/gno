package provider

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
	"strings"
)

func TestGetProfile(t *testing.T) {
	user1 := testutils.TestAddress("user1")
	std.TestSetOrigCaller(user1)
	UpsertProfile("firstname", "John")
	UpsertProfile("name", "Gopher")

	result:=Get("profile",user1)
	t.Log(result)
	if !strings.Contains(result,"name: Gopher"){
		t.Error("Bad")
	}

}