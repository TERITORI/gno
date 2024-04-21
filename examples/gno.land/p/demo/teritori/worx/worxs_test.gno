package worx

import (
	"testing"
	"gno.land/p/demo/rand"
	"gno.land/p/demo/testutils"
	"gno.land/p/demo/ufmt"
	"std"
)

func TestAddGet(t *testing.T) {
	keeper := NewWorxKeeper()
	user1 := testutils.TestAddress("user1")
	if len(keeper.Get()) != 0{
		t.Fatalf("Keeper is not empty initialized")
	}

	fillRandomWorx(keeper, 10123423, user1)
	if len(keeper.Get()) != 1{
		t.Fatalf("Keeper Worx was not added to keeper 1")
	}

	fillRandomWorx(keeper, 10123423, user1)
	if len(keeper.Get()) != 2{
		t.Fatalf("Keeper Worx was not added to keeper 2")
	}
}

func TestGetFromDate(t *testing.T) {
	keeper := NewWorxKeeper()
	user1 := testutils.TestAddress("user1")
	if len(keeper.Get()) != 0{
		t.Fatalf("Keeper is not empty initialized")
	}
	
	for i:=0; i < 100; i++ {
		fillRandomWorx(keeper, int64(i*10), user1)
	}

	if len(keeper.Get()) != 100{
		t.Fatalf("Keeper Worx was not totally added")
	}

	if len(keeper.GetFromDate(1003)) != 0 {
		t.Fatalf("Get From Date Should have found 0 registers")
	}

	if len(keeper.GetFromDate(903)) != 9 {
		t.Fatalf("Get From Date Should have found 9 registers")
	}

}

func fillRandomWorx(keeper *WorxKeeper, timestamp int64, address std.Address){
	r := rand.New()
	keeper.Store(NewWorx(
		r.Intn(25),
		"somekey",
		address,
		r.Intn(100),
		timestamp,
	))
}