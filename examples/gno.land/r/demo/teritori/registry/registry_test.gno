package registry

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
	functionID:="SOMEID"
	var cb functionCB = func(args ...interface{})[]interface{}{
		//t.Errorf("dataType",dataType)
		return nil
	}
	Register(functionID, cb)
	Exec(functionID)
}