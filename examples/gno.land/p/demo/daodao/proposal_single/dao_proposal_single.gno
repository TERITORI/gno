package dao_proposal_single

import (
	"std"
	"strconv"
	"time"

	"gno.land/p/demo/avl"
	dao_interfaces "gno.land/p/demo/daodao/interfaces"
	"gno.land/p/demo/ujson"
)

type DAOProposalSingleOpts struct {
	/// The threshold a proposal must reach to complete.
	Threshold Threshold
	/// The default maximum amount of time a proposal may be voted on
	/// before expiring.
	MaxVotingPeriod time.Duration
	/// The minimum amount of time a proposal must be open before
	/// passing. A proposal may fail before this amount of time has
	/// elapsed, but it will not pass. This can be useful for
	/// preventing governance attacks wherein an attacker aquires a
	/// large number of tokens and forces a proposal through.
	MinVotingPeriod time.Duration // 0 means no minimum
	/// If set to true only members may execute passed
	/// proposals. Otherwise, any address may execute a passed
	/// proposal.
	OnlyMembersExecute bool
	/// Allows changing votes before the proposal expires. If this is
	/// enabled proposals will not be able to complete early as final
	/// vote information is not known until the time of proposal
	/// expiration.
	AllowRevoting bool
	/// Information about what addresses may create proposals.
	// preProposeInfo PreProposeInfo
	/// If set to true proposals will be closed if their execution
	/// fails. Otherwise, proposals will remain open after execution
	/// failure. For example, with this enabled a proposal to send 5
	/// tokens out of a DAO's treasury with 4 tokens would be closed when
	/// it is executed. With this disabled, that same proposal would
	/// remain open until the DAO's treasury was large enough for it to be
	/// executed.
	CloseProposalOnExecutionFailure bool
}

type DAOProposalSingle struct {
	dao_interfaces.IProposalModule

	core      dao_interfaces.IDAOCore
	opts      *DAOProposalSingleOpts
	proposals []Proposal
}

func NewDAOProposalSingle(core dao_interfaces.IDAOCore, opts *DAOProposalSingleOpts) *DAOProposalSingle {
	if core == nil {
		panic("core cannot be nil")
	}

	if opts == nil {
		panic("opts cannot be nil")
	}

	if opts.AllowRevoting {
		panic("allow revoting not implemented")
	}

	if opts.OnlyMembersExecute {
		panic("only members execute not implemented")
	}

	if opts.CloseProposalOnExecutionFailure {
		panic("close proposal on execution failure not implemented")
	}

	// TODO: support other threshold types
	threshold := opts.Threshold.ThresholdQuorum
	if threshold == nil {
		panic("opts.Threshold must be of type ThresholdQuorum")
	}

	thresholdPercent := threshold.Threshold.Percent
	if thresholdPercent == nil {
		panic("opts.Threshold.Threshold must be of type Percent")
	}
	if *thresholdPercent > 10000 {
		panic("opts.Threshold.Threshold must be <= 100%")
	}

	quorumPercent := threshold.Quorum.Percent
	if quorumPercent == nil {
		panic("opts.Threshold.Quorum must be of type Percent")
	}
	if *quorumPercent > 10000 {
		panic("opts.Threshold.Quorum must be <= 100%")
	}

	return &DAOProposalSingle{core: core, opts: opts}
}

func (d *DAOProposalSingle) Render(path string) string {
	minVotingPeriodStr := "No minimum voting period"
	if d.opts.MinVotingPeriod != 0 {
		minVotingPeriodStr = "Min voting period: " + d.opts.MinVotingPeriod.String()
	}

	executeStr := "Any address may execute passed proposals"
	if d.opts.OnlyMembersExecute {
		executeStr = "Only members may execute passed proposals"
	}

	revotingStr := "Revoting is not allowed"
	if d.opts.AllowRevoting {
		revotingStr = "Revoting is allowed"
	}

	closeOnExecFailureStr := "Proposals will remain open after execution failure"
	if d.opts.CloseProposalOnExecutionFailure {
		closeOnExecFailureStr = "Proposals will be closed if their execution fails"
	}

	thresholdStr := ""
	if threshold := d.opts.Threshold.ThresholdQuorum; threshold != nil {
		thresholdStr = "Threshold: " + threshold.Threshold.Percent.String() + "\n\n" +
			"Quorum: " + threshold.Quorum.Percent.String()
	}

	proposalsStr := "## Proposals\n"
	for _, p := range d.proposals {
		messagesStr := ""
		for _, m := range p.Messages {
			messagesStr += "- " + m.(dao_interfaces.ExecutableMessage).String() + "\n"
		}

		proposalsStr += "### #" + strconv.Itoa(p.ID) + " " + p.Title + "\n" +
			"Status: " + p.Status.String() + "\n\n" +
			"Proposed by " + p.Proposer.String() + "\n\n" +
			p.Description + "\n\n" +
			"Votes summary:" + "\n\n" +
			"- Yes: " + strconv.FormatUint(p.Votes.Yes, 10) + "\n" +
			"- No: " + strconv.FormatUint(p.Votes.No, 10) + "\n" +
			"- Abstain: " + strconv.FormatUint(p.Votes.Abstain, 10) + "\n\n" +
			"Total: " + strconv.FormatUint(p.Votes.Total(), 10) + "\n" +
			"#### Messages\n" +
			messagesStr +
			"#### Votes\n"

		// /* dev
		p.Ballots.Iterate("", "", func(k string, v interface{}) bool {
			ballot := v.(Ballot)
			proposalsStr += "- " + k + " voted " + ballot.Vote.String() + "\n"
			return false
		})
		// */

		/* test3
		ballotsCount := p.Ballots.Size()
		for i := 0; i < ballotsCount; i++ {
			k, v := p.Ballots.GetByIndex(i)
			ballot := v.(dao_interfaces.Ballot)
			proposalsStr += "- " + k + " voted " + ballot.Vote.String() + "\n"
		}
		*/

		proposalsStr += "\n"
	}

	return "# Single choice proposals module" + "\n" +
		"## Summary" + "\n" +
		"Max voting period: " + d.opts.MaxVotingPeriod.String() + "\n\n" +
		minVotingPeriodStr + "\n\n" +
		executeStr + "\n\n" +
		revotingStr + "\n\n" +
		closeOnExecFailureStr + "\n\n" +
		thresholdStr + "\n\n" +
		proposalsStr
}

func (d *DAOProposalSingle) Propose(title string, description string, messages []dao_interfaces.ExecutableMessage) int {
	id := len(d.proposals)
	// TODO: auth
	d.proposals = append(d.proposals, Proposal{
		ID:          id,
		Title:       title,
		Description: description,
		Messages:    messages,
		Proposer:    std.GetOrigCaller(),
		Ballots:     avl.NewTree(), // dev
		// Ballots: avl.NewMutTree(), // test3
		Status: ProposalStatusOpen,
	})
	return id
}

func (d *DAOProposalSingle) GetBallot(proposalID int, memberAddress std.Address) Ballot {
	if len(d.proposals) <= proposalID || proposalID < 0 {
		panic("proposal does not exist")
	}
	proposal := d.proposals[proposalID]
	ballot, has := proposal.Ballots.Get(memberAddress.String())
	if !has {
		panic("ballot does not exist")
	}
	return ballot.(Ballot)
}

type VoteWithRationale struct {
	Vote      Vote
	Rationale string
}

func (v *VoteWithRationale) FromJSON(ast *ujson.JSONASTNode) {
	ast.ParseObject([]*ujson.ParseKV{
		{Key: "vote", Value: &v.Vote},
		{Key: "rationale", Value: &v.Rationale},
	})
}

func (d *DAOProposalSingle) VoteJSON(proposalID int, voteJSON string) {
	var v VoteWithRationale
	ujson.ParseAny(voteJSON, &v)

	voter := std.PrevRealm().Addr()

	if len(d.proposals) <= proposalID || proposalID < 0 {
		panic("proposal does not exist")
	}
	proposal := d.proposals[proposalID]
	// TODO: check proposal expiration

	votePower := d.core.VotingModule().VotingPowerAtHeight(voter, 0)
	if votePower == 0 {
		panic("you're not a member")
	}

	// TODO: handle revoting
	if ok := proposal.Ballots.Has(voter.String()); ok {
		panic("you already voted")
	}
	proposal.Ballots.Set(voter.String(), Ballot{
		Vote:      v.Vote,
		Power:     votePower,
		Rationale: v.Rationale,
	})

	proposal.Votes.Add(v.Vote, votePower)

	d.updateStatus(proposalID)
}

func (d *DAOProposalSingle) Execute(proposalID int) {
	executer := std.GetOrigCaller()

	if len(d.proposals) <= proposalID || proposalID < 0 {
		panic("proposal does not exist")
	}
	prop := d.proposals[proposalID]

	d.updateStatus(proposalID)
	if prop.Status != ProposalStatusPassed {
		panic("proposal is not passed")
	}

	for _, m := range prop.Messages {
		d.core.Registry().Execute(m)
	}

	d.proposals[proposalID].Status = ProposalStatusExecuted
}

type ProposalRequest struct {
	Title       string
	Description string
	Messages    *ujson.JSONASTNode
}

func (pr *ProposalRequest) FromJSON(ast *ujson.JSONASTNode) {
	ast.ParseObject([]*ujson.ParseKV{
		{Key: "title", Value: &pr.Title},
		{Key: "description", Value: &pr.Description},
		{Key: "messages", Value: &pr.Messages},
	})
}

func (d *DAOProposalSingle) ProposeJSON(proposalJSON string) int {
	var req ProposalRequest
	ujson.ParseAny(proposalJSON, &req)
	msgs := d.core.Registry().MessagesFromJSON(req.Messages.String())
	return d.Propose(req.Title, req.Description, msgs)
}

func (d *DAOProposalSingle) Proposals() []Proposal {
	return d.proposals
}

func (d *DAOProposalSingle) ProposalsJSON(limit int, startAfter string, reverse bool) string {
	return ujson.FormatSlice(d.proposals)
}

func (d *DAOProposalSingle) Threshold() Threshold {
	return d.opts.Threshold
}

func (d *DAOProposalSingle) updateStatus(proposalID int) {
	proposal := d.proposals[proposalID]
	if proposal.Status == ProposalStatusOpen && d.isPassed(proposalID) {
		d.proposals[proposalID].Status = ProposalStatusPassed
		return
	}
}

func (d *DAOProposalSingle) isPassed(proposalID int) bool {
	proposal := d.proposals[proposalID]

	// TODO: support other threshold types
	threshold := d.opts.Threshold.ThresholdQuorum.Threshold
	quorum := d.opts.Threshold.ThresholdQuorum.Quorum

	totalPower := d.core.VotingModule().TotalPowerAtHeight(0)

	if !doesVoteCountPass(proposal.Votes.Total(), totalPower, quorum) {
		return false
	}

	// TODO: handle expiration
	options := totalPower - proposal.Votes.Abstain
	return doesVoteCountPass(proposal.Votes.Yes, options, threshold)
}

func doesVoteCountPass(yesVotes uint64, options uint64, percent PercentageThreshold) bool {
	if options == 0 {
		return false
	}
	percentValue := uint64(*percent.Percent)
	votes := yesVotes * 10000
	threshold := options * percentValue
	return votes >= threshold
}
