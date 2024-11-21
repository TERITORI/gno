package worx_aggregator

import (
	"std"
	"testing"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
)

func TestPushCallerNotRegistered(t *testing.T) {
	user1 := testutils.TestAddress("user1")
	defer func() {
		if v := recover(); v == nil {
			t.Fatalf("expected panic got no error: ")
		}
	}()
	Push(1, "", user1, 3, 10)
}

func TestHappyPath(t *testing.T) {
	registeredProviders = avl.NewTree()
	worxByAddress = avl.NewTree()

	realm := testutils.TestAddress("realm")
	admin := testutils.TestAddress("admin")
	user1 := testutils.TestAddress("user1")

	setAdminAddress(admin)

	std.TestSetOrigCaller(admin)

	RegisterDataProvider(realm)

	std.TestSetOrigCaller(realm)

	Push(1, "", user1, 3, 10)
}
