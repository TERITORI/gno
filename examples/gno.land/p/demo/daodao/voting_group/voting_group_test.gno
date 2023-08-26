package dao_voting_group

import (
	"std"
	"testing"

	"gno.land/r/demo/groups"
)

func Test(t *testing.T) {
	{
		g := groups.CreateGroup("test_voting_group")
		v := NewVotingGroup(g)
		got := v.TotalPower()
		expected := uint64(0)
		if got != expected {
			t.Fatalf("expected %q, got %q.", expected, got)
		}
	}
}
