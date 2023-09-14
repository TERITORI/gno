package dao_interfaces

import (
	"std"

	"gno.land/p/demo/ujson"
)

type ModuleInfo struct {
	Kind    string
	Version string
}

// NOTE: Some queries take a height param in DA0-DA0 contracts, but since gno seem to aim to support queries at any height, we shouldn't need it

type IVotingModule interface {
	Core() IDAOCore
	Info() ModuleInfo
	Render(path string) string
	VotingPower(address std.Address) (power uint64)
	TotalPower() uint64
}

type VotingModuleFactory func(core IDAOCore) IVotingModule

type IProposalModule interface {
	Core() IDAOCore
	Info() ModuleInfo
	Render(path string) string
	Execute(proposalId int)
	VoteJSON(proposalID int, voteJSON string)
	ProposeJSON(proposalJSON string) int
	ProposalsJSON(limit int, startAfter string, reverse bool) string
}

type ProposalModuleFactory func(core IDAOCore) IProposalModule
