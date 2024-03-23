package gh

import (
	"std"
	"testing"
	"time"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/testutils"
)

func TestOracleUpsertUserIsNotOracle(t *testing.T) {
	oracleAddr = "g1test1234" 
	var randomuser = "g1unknown_player"
	user := testutils.TestAddress("user")
	defer func() {
		if r := recover(); r != nil {
		}
	}()
	OracleUpsertAccount("acountID", "villaquiranm","john doe","user")
	t.Fatalf("should fail because not admin")
}

func TestOracleUpsertUserOk(t *testing.T) {
	oracleAddr = "g1random" 
	if accounts.Size() != 0 {
		t.Fatalf("Accounts is not empty")
	}
	now := time.Now()
	
	std.TestSetOrigCaller(oracleAddr)

	var randomuser = "g1unknown_player"
	OracleUpsertAccount("acountID", "villaquiranm","john doe","user")

	if accounts.Size() != 1 {
		t.Fatalf("User was not created")
	}

	OracleUpsertAccount("acountID", "villaquiranm","john doe","user")

	if accounts.Size() != 1 {
		t.Fatalf("User was created more than once")
	}

	if OracleLastUpdated().Unix() < now.Unix() {
		t.Fatalf("OracleLastUpdated was not changed")
	}
}

func TestAssertIsOracle(t *testing.T) {
	std.TestSetOrigCaller(adminAddr)
	AdminSetOracleAddr("g1random123")
	defer func() {
        if r := recover(); r != nil {
        }
    }()
	assertIsOracle()
	t.Fatalf("should fail because user is not oracle")
}