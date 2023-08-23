package dao_realm

import (
	"fmt"
	"std"
	"testing"

	dao_interfaces "gno.land/p/demo/daodao/interfaces"
	"gno.land/p/demo/jsonutil"
	"gno.land/r/demo/groups"
	modboards "gno.land/r/demo/modboards"
	"gno.land/r/demo/users"
)

func TestInit(t *testing.T) {
	{
		proposalsJSON := GetProposalsJSON(0)
		expected := "[]"
		if proposalsJSON != expected {
			t.Fatalf("Expected %s, got %s", expected, proposalsJSON)
		}
	}

	{
		membersJSON := GetMembersJSON()
		expected := `[{"id":0,"address":"g1747t5m2f08plqjlrjk2q0qld7465hxz8gkx59c","weight":1,"metadata":""},{"id":1,"address":"g108cszmcvs4r3k67k7h5zuhm4el3qhlrxzhshtv","weight":1,"metadata":""},{"id":2,"address":"g14u5eaheavy0ux4dmpykg2gvxpvqvexm9cyg58a","weight":1,"metadata":""},{"id":3,"address":"g1ckn395mpttp0vupgtratyufdaakgh8jgkmr3ym","weight":1,"metadata":""},{"id":4,"address":"g1wymu47drhr0kuq2098m792lytgtj2nyx77yrsm","weight":1,"metadata":""}]`
		if membersJSON != expected {
			t.Fatalf("Expected %s, got %s", expected, membersJSON)
		}
	}
}

func TestUpdateMembers(t *testing.T) {
	var membersJSON string

	{
		ProposeJSON(0, "Test prop", "A description", fmt.Sprintf(`[{"type": "gno.land/r/demo/groups.AddMember", "payload": {"groupId": %d, "weight": 1, "address": "0x42", "metadata": "hello"}}]`, groupID))
		Vote(0, 0, dao_interfaces.VoteYes, "testing")
		Execute(0, 0)
		membersJSON = GetMembersJSON()
		expected := fmt.Sprintf(`[{"id":0,"address":"g1747t5m2f08plqjlrjk2q0qld7465hxz8gkx59c","weight":1,"metadata":""},{"id":1,"address":"g108cszmcvs4r3k67k7h5zuhm4el3qhlrxzhshtv","weight":1,"metadata":""},{"id":2,"address":"g14u5eaheavy0ux4dmpykg2gvxpvqvexm9cyg58a","weight":1,"metadata":""},{"id":3,"address":"g1ckn395mpttp0vupgtratyufdaakgh8jgkmr3ym","weight":1,"metadata":""},{"id":4,"address":"g1wymu47drhr0kuq2098m792lytgtj2nyx77yrsm","weight":1,"metadata":""},{"id":5,"address":"0x42","weight":1,"metadata":"hello"}]`)
		if membersJSON != expected {
			t.Fatalf("Expected %s, got %s", expected, membersJSON)
		}
	}

	{
		children := jsonutil.ParseSlice(membersJSON)
		var member groups.Member
		jsonutil.ParseASTAny(children[0], &member)

		ProposeJSON(0, "Test prop 2", "A description", fmt.Sprintf(`[{"type": "gno.land/r/demo/groups.DeleteMember", "payload": {"groupId": %d, "memberId": %d}}]`, groupID, member.GetID()))
		Vote(0, 1, dao_interfaces.VoteYes, "testing")
		Execute(0, 1)
		membersJSON = GetMembersJSON()
		expected := fmt.Sprintf(`[{"id":1,"address":"g108cszmcvs4r3k67k7h5zuhm4el3qhlrxzhshtv","weight":1,"metadata":""},{"id":2,"address":"g14u5eaheavy0ux4dmpykg2gvxpvqvexm9cyg58a","weight":1,"metadata":""},{"id":3,"address":"g1ckn395mpttp0vupgtratyufdaakgh8jgkmr3ym","weight":1,"metadata":""},{"id":4,"address":"g1wymu47drhr0kuq2098m792lytgtj2nyx77yrsm","weight":1,"metadata":""},{"id":5,"address":"0x42","weight":1,"metadata":"hello"}]`)
		if membersJSON != expected {
			t.Fatalf("Expected %s, got %s", expected, membersJSON)
		}
	}
}

func TestModeration(t *testing.T) {
	std.TestSetOrigSend(std.Coins{{Amount: 200000000, Denom: "ugnot"}}, nil)
	users.Register(std.Address(""), "testerer", "")
	boardID, ok := modboards.GetBoardIDFromName(mainBoardName)
	if !ok {
		t.Fatalf("Board %s not found", mainBoardName)
	}
	modboards.CreateThread(boardID, "Test thread", "Offensive stuff")
	modboards.FlagPost(boardID, 1, 1)
	{
		expected := `\[[post](/r/demo/modboards?help&__func=CreateThread&bid=1&body.type=textarea)]\[[see flags](/r/demo/modboards:dao_realm/flags)]

----------------------------------------
## [Test thread](/r/demo/modboards:dao_realm/1)

Offensive stuff
\- [@testerer](/r/users:testerer), [2009-02-13 11:31pm UTC](/r/demo/modboards:dao_realm/1) \[[🚩](/r/demo/modboards?help&__func=FlagPost&boardID=1&threadID=1&postID=1)] \[[x](/r/demo/modboards?help&__func=DeletePost&bid=1&threadid=1&postid=1)] (0 replies, 1 red flags)

`
		render := modboards.Render(mainBoardName)
		if render != expected {
			t.Fatalf("Expected %s, got `%s`", expected, render)
		}
	}

	ProposeJSON(0, "Test prop", "A description", fmt.Sprintf(`[{"type": "gno.land/r/demo/modboards.DeletePost", "payload": {"boardId": %d, "threadId": 1, "postId": 1, "reason": "testing"}}]`, boardID))
	Vote(0, 2, dao_interfaces.VoteYes, "testing")
	Execute(0, 2)
	{
		expected := `\[[post](/r/demo/modboards?help&__func=CreateThread&bid=1&body.type=textarea)]\[[see flags](/r/demo/modboards:dao_realm/flags)]

`
		render := modboards.Render(mainBoardName)
		if render != expected {
			t.Fatalf("Expected %s, got `%s`", expected, render)
		}
	}
}
