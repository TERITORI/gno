package worx_aggregator

import (
	"testing"
	"gno.land/p/demo/testutils"
)

func TestPushCallerNotRegistered(t * testing.T){
	user1 := testutils.TestAddress("user1")
	defer func() {
		if v := recover(); v == nil {
			t.Fatalf("expected panic got no error: ")
		}
	}()
	Push(1, "", user1, 3, 10)
}
