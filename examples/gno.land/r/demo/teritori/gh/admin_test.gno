package gh

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
)

func TestAssertIsAdmin(t *testing.T) {
	adminAddr = "g1test1234" 
	randomuser := testutils.TestAddress("g1unknown_player")
	defer func() {
        if r := recover(); r != nil {
        }
    }()
	std.TestSetOrigCaller(randomuser)
	assertIsAdmin()
	t.Fatalf("should fail because not admin")
}

