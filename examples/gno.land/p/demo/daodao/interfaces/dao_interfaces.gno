package dao_interfaces

import (
	"std"
	"strconv"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/ujson"
)

type IVotingModule interface {
	VotingPower(addr std.Address) uint64
	TotalPower() uint64
	Render(path string) string
}

type Ballot struct {
	Power     uint64
	Vote      Vote
	Rationale string
}

func (b Ballot) ToJSON() string {
	return ujson.FormatObject([]ujson.FormatKV{
		{Key: "power", Value: b.Power},
		{Key: "vote", Value: b.Vote},
		{Key: "rationale", Value: b.Rationale},
	})
}

type Votes struct {
	Yes     uint64
	No      uint64
	Abstain uint64
}

func (v *Votes) Add(vote Vote, power uint64) {
	switch vote {
	case VoteYes:
		v.Yes += power
	case VoteNo:
		v.No += power
	case VoteAbstain:
		v.Abstain += power
	default:
		panic("unknown vote kind")
	}
}

func (v *Votes) Remove(vote Vote, power uint64) {
	switch vote {
	case VoteYes:
		v.Yes -= power
	case VoteNo:
		v.No -= power
	case VoteAbstain:
		v.Abstain -= power
	default:
		panic("unknown vote kind")
	}
}

func (v *Votes) Total() uint64 {
	return v.Yes + v.No + v.Abstain
}

func (v Votes) ToJSON() string {
	return ujson.FormatObject([]ujson.FormatKV{
		{Key: "yes", Value: v.Yes},
		{Key: "no", Value: v.No},
		{Key: "abstain", Value: v.Abstain},
	})
}

type Proposal struct {
	ID          int
	Title       string
	Description string
	Proposer    std.Address
	Messages    []ExecutableMessage
	Ballots     *avl.Tree // dev
	// Ballots *avl.MutTree // test3
	Votes  Votes
	Status ProposalStatus
}

var _ ujson.JSONAble = (*Proposal)(nil)

func (p Proposal) ToJSON() string {
	return ujson.FormatObject([]ujson.FormatKV{
		{Key: "id", Value: p.ID},
		{Key: "title", Value: p.Title},
		{Key: "description", Value: p.Description},
		{Key: "proposer", Value: p.Proposer},
		{Key: "messages", Value: ujson.FormatSlice(p.Messages), Raw: true},
		{Key: "ballots", Value: p.Ballots},
		{Key: "votes", Value: p.Votes},
		{Key: "status", Value: p.Status},
	})
}

type ProposalStatus int

const (
	ProposalStatusOpen ProposalStatus = iota
	ProposalStatusPassed
	ProposalStatusExecuted
)

func (p ProposalStatus) ToJSON() string {
	return ujson.FormatString(p.String())
}

func (p ProposalStatus) String() string {
	switch p {
	case ProposalStatusOpen:
		return "Open"
	case ProposalStatusPassed:
		return "Passed"
	case ProposalStatusExecuted:
		return "Executed"
	default:
		return "Unknown(" + strconv.Itoa(int(p)) + ")"
	}
}

type Vote int

const (
	VoteYes Vote = iota
	VoteNo
	VoteAbstain
)

func (v Vote) ToJSON() string {
	return ujson.FormatString(v.String())
}

func (v Vote) String() string {
	switch v {
	case VoteYes:
		return "Yes"
	case VoteNo:
		return "No"
	case VoteAbstain:
		return "Abstain"
	default:
		return "Unknown(" + strconv.Itoa(int(v)) + ")"
	}
}

type IProposalModule interface {
	Propose(
		title string,
		description string,
		actions []ExecutableMessage,
	)
	Vote(proposalId int, vote Vote, rationale string)
	Execute(proposalId int)
	Threshold() Threshold

	Proposals() []Proposal
	GetBallot(proposalId int, addr std.Address) Ballot

	Render(path string) string
}
