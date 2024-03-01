package escrow

import (
	"std"
	"strconv"
	"strings"
	"time"

	fmt "gno.land/p/demo/ufmt"
	"gno.land/r/demo/gopher20"
	"gno.land/r/demo/users"
)

type ContractStatus uint32

const (
	CREATED   ContractStatus = 1
	ACCEPTED  ContractStatus = 2
	CANCELED  ContractStatus = 3
	PAUSED    ContractStatus = 4
	COMPLETED ContractStatus = 5
)

func (x ContractStatus) String() string {
	switch x {
	case CREATED:
		return "CREATED"
	case ACCEPTED:
		return "ACCEPTED"
	case CANCELED:
		return "CANCELED"
	case PAUSED:
		return "PAUSED"
	case COMPLETED:
		return "COMPLETED"
	}
	return "UNKNOWN"
}

type MilestoneStatus uint32

const (
	MS_OPEN      MilestoneStatus = 1
	MS_PROGRESS  MilestoneStatus = 2
	MS_REVIEW    MilestoneStatus = 3
	MS_COMPLETED MilestoneStatus = 4
)

func (x MilestoneStatus) String() string {
	switch x {
	case MS_OPEN:
		return "MS_OPEN"
	case MS_PROGRESS:
		return "MS_PROGRESS"
	case MS_REVIEW:
		return "MS_REVIEW"
	case MS_COMPLETED:
		return "MS_COMPLETED"
	}
	return "UNKNOWN"
}

type Milestone struct {
	title    string
	amount   uint64
	paid     uint64
	duration uint64
	link     string // milestone reference link
	funded   bool
	status   MilestoneStatus
}

type Contract struct {
	id                 uint64
	sender             string
	contractor         string
	funder             string // funder address
	escrowToken        string // grc20 token
	metadata           string // store data for image, tags, name, description, links for twitter/github...
	status             ContractStatus
	expireAt           uint64
	funderFeedback     string
	contractorFeedback string
	milestones         []Milestone
	activeMilestone    uint64
	pausedBy           string
	conflictHandler    string // can be a realm path or a caller address
	handlerCandidate   string // conflict handler candidate suggested by one party
	handlerSuggestor   string // the suggestor off the conflict handler candidate
}

// Escrow State
var contracts []Contract

func CurrentRealm() string {
	return std.CurrentRealm().Addr().String()
}

func CreateContract(
	contractor string,
	funder string,
	escrowToken string, // grc20 token
	metadata string,
	expiryDuration uint64,
	milestoneTitles string,
	milestoneAmounts string,
	milestoneDurations string,
	milestoneLinks string,
	conflictHandler string,
) {
	caller := std.GetOrigCaller()
	if expiryDuration == 0 {
		panic("invalid expiryDuration")
	}
	if escrowToken == "" {
		panic("invalid escrow token")
	}

	if contractor == "" {
		panic("contractor should not be empty")
	}

	if funder == "" {
		panic("funder should not be empty")
	}

	if contractor != caller.String() && funder != caller.String() {
		panic("caller should be one of contractor or funder")
	}

	milestoneTitleArr := strings.Split(milestoneTitles, ",")
	milestoneAmountArr := strings.Split(milestoneAmounts, ",")
	milestoneDurationArr := strings.Split(milestoneDurations, ",")
	milestoneLinkArr := strings.Split(milestoneLinks, ",")

	if len(milestoneTitleArr) == 0 {
		panic("no milestone titles provided")
	}

	if len(milestoneTitleArr) != len(milestoneAmountArr) ||
		len(milestoneTitleArr) != len(milestoneDurationArr) ||
		len(milestoneTitleArr) != len(milestoneLinkArr) {
		panic("mismatch on milestones title, amount, duration and link")
	}

	milestones := []Milestone{}
	for i, title := range milestoneTitleArr {
		amount, err := strconv.Atoi(milestoneAmountArr[i])
		if err != nil {
			panic(err)
		}
		duration, err := strconv.Atoi(milestoneDurationArr[i])
		if err != nil {
			panic(err)
		}
		milestones = append(milestones, Milestone{
			title:    title,
			amount:   uint64(amount),
			paid:     false,
			duration: uint64(duration),
			link:     milestoneLinkArr[i],
			funded:   false,
			status:   MS_OPEN,
		})
	}

	contractId := uint64(len(contracts))
	contracts = append(contracts, Contract{
		id:              contractId,
		sender:          caller.String(),
		contractor:      contractor,
		funder:          funder,
		escrowToken:     escrowToken,
		metadata:        metadata,
		status:          CREATED,
		expireAt:        uint64(time.Now().Unix()) + expiryDuration,
		milestones:      milestones,
		activeMilestone: 0,
		conflictHandler: conflictHandler,
	})
}

func CancelContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != CREATED {
		panic("contract can only be cancelled at CREATED status")
	}

	if contract.sender != caller.String() {
		panic("not authorized to cancel the contract")
	}

	contracts[contractId].status = CANCELED
}

func AcceptContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != CREATED {
		panic("contract can only be accepted at CREATED status")
	}

	if contract.expireAt < uint64(time.Now().Unix()) {
		panic("contract already expired")
	}

	if contract.sender == caller.String() {
		panic("contract sender is not able to accept the contract")
	}

	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract counterparty is allowed to accept")
	}
	contracts[contractId].status = ACCEPTED
}

func PauseContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != ACCEPTED {
		panic("contract can only be paused at ACCEPTED status")
	}

	if contract.contractor != caller.String() && contract.funder != caller.String() {
		panic("only contractor or funder can pause")
	}
	contracts[contractId].status = PAUSED
	contracts[contractId].pausedBy = caller.String()
}

func ResumeContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != PAUSED {
		panic("contract can only be resumed at PAUSED status")
	}

	if contract.pausedBy != caller.String() {
		panic("only paused party can resume")
	}
	contracts[contractId].status = ACCEPTED
	contracts[contractId].pausedBy = ""
}

// pay partial amount
func PayActiveMilestone(contractId uint64, amount uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() {
		panic("only contract funder can pay the milestone")
	}

	if contract.status == CREATED || contract.status == CANCELED {
		panic("cannot pay on not accepted contract")
	}

	milestoneId := contract.activeMilestone
	milestone := contract.milestones[milestoneId]
	if !milestone.funded {
		panic("not funded for the milestone")
	}
	if milestone.paid+amount > milestone.amount {
		panic("could not pay more than milestone amount")
	}

	gopher20.Transfer(
		users.AddressOrName(contract.contractor),
		amount)
	contracts[contractId].milestones[milestoneId].paid += amount
}

// pay unpaid amount and move to next milestone
func PayAndCompleteActiveMilestone(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() {
		panic("only contract funder can pay the milestone")
	}

	if contract.status == CREATED || contract.status == CANCELED {
		panic("cannot pay on not accepted contract")
	}

	milestoneId := contract.activeMilestone
	milestone := contract.milestones[milestoneId]
	unpaid := milestone.amount - milestone.paid
	if unpaid > 0 {
		gopher20.Transfer(
			users.AddressOrName(contract.contractor),
			unpaid)
		contracts[contractId].milestones[milestoneId].paid += unpaid
	}
	contracts[contractId].milestones[milestoneId].status = MS_COMPLETED
	contracts[contractId].activeMilestone += 1
}

func SetActiveMilestoneInReview(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participant can execute the action")
	}

	if contract.status != ACCEPTED {
		panic("contract is not on accepted status")
	}

	milestoneId := contract.activeMilestone
	milestone := contract.milestones[milestoneId]
	if milestone.status != MS_PROGRESS {
		panic("milestone is not in progress")
	}

	contracts[contractId].milestones[milestoneId].status = MS_REVIEW
}

func SetActiveMilestoneInProgress(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participant can execute the action")
	}

	if contract.status != ACCEPTED {
		panic("contract is not on accepted status")
	}

	milestoneId := contract.activeMilestone
	milestone := contract.milestones[milestoneId]
	if milestone.status != MS_REVIEW {
		panic("milestone is not in review")
	}

	contracts[contractId].milestones[milestoneId].status = MS_PROGRESS
}

// fund milestone
func StartMilestone(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() {
		panic("only contract funder can pay the milestone")
	}

	if contract.status == CREATED {
		panic("cannot start milestone on not accepted contract")
	}

	milestoneId := contract.activeMilestone
	if len(contract.milestones) <= int(milestoneId) {
		panic("new milestone is not prepared")
	}
	milestone := contract.milestones[milestoneId]
	if milestone.funded {
		panic("milestone already funded")
	}
	gopher20.TransferFrom(
		users.AddressOrName(caller.String()),
		users.AddressOrName(std.CurrentRealm().Addr().String()),
		milestone.amount)
	contracts[contractId].milestones[milestoneId].funded = true
	contracts[contractId].milestones[milestoneId].status = MS_PROGRESS
}

func AddUpcomingMilestone(
	contractId uint64,
	title string,
	amount uint64,
	duration uint64,
	link string,
) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participants can add upcoming milestone")
	}

	if contract.status == COMPLETED {
		panic("milestone can not be modified on completed contract")
	}

	contracts[contractId].milestones = append(contracts[contractId].milestones, Milestone{
		title:    title,
		amount:   amount,
		paid:     false,
		duration: duration,
		funded:   false,
		status:   MS_OPEN,
	})
}

func CancelUpcomingMilestone(contractId uint64, milestoneId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participants can cancel upcoming milestone")
	}

	if contract.status == COMPLETED {
		panic("milestone can not be modified on completed contract")
	}

	milestones := contract.milestones
	if len(milestones) <= int(milestoneId) {
		panic("milestone is not valid")
	}
	milestone := milestones[milestoneId]
	if milestone.funded {
		panic("cannot cancel funded milestone")
	}
	contracts[contractId].milestones = append(milestones[:milestoneId], milestones[milestoneId+1:]...)
}

func CompleteContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != ACCEPTED {
		panic("contract can only be completed at ACCEPTED status")
	}

	if contract.funder != caller.String() {
		panic("only contract funder can complete")
	}

	milestones := contract.milestones
	milestoneId := contract.activeMilestone
	if int(milestoneId) < len(milestones) && milestones[milestoneId].funded {
		panic("active milestone exists")
	}

	contracts[contractId].status = COMPLETED
}

func SuggestConflictHandler(contractId uint64, conflictHandler string) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participants can suggest conflict handler")
	}

	if contract.conflictHandler == conflictHandler {
		panic("same contract handler is already set")
	}

	contracts[contractId].handlerCandidate = conflictHandler
	contracts[contractId].handlerSuggestor = caller.String()
}

func ApproveConflictHandler(contractId uint64, conflictHandler string) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only a contract participant can approve conflict handler")
	}

	if contract.handlerSuggestor == caller.String() {
		panic("conflict handler suggestor cannot approve suggested handler")
	}

	if contract.handlerCandidate != conflictHandler {
		panic("handlerCandidate is different from approving handler")
	}
	contracts[contractId].conflictHandler = conflictHandler
}

func CompleteContractByConflictHandler(contractId uint64, contractorAmount uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != PAUSED {
		panic("contract can only be processed by DAO at PAUSED status")
	}

	if contract.conflictHandler != caller.String() &&
		contract.conflictHandler != std.PrevRealm().PkgPath() {
		panic("only conflictHandler is allowed for this operation")
	}

	milestones := contract.milestones
	milestoneId := contract.activeMilestone
	if len(milestones) <= int(milestoneId) {
		panic("active milestone is not valid")
	}
	milestone := milestones[milestoneId]
	if !milestone.funded {
		panic("milestone should be funded")
	}
	unpaidAmount := milestone.amount - milestone.paid

	funderAmount := unpaidAmount - contractorAmount

	gopher20.Transfer(
		users.AddressOrName(contract.contractor),
		contractorAmount)
	gopher20.Transfer(
		users.AddressOrName(contract.funder),
		funderAmount)

	contracts[contractId].milestones[milestoneId].paid += contractorAmount
	contracts[contractId].milestones[milestoneId].status = MS_COMPLETED
	contracts[contractId].activeMilestone += 1
	contracts[contractId].status = COMPLETED
}

func GiveFeedback(contractId uint64, feedback string) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != COMPLETED {
		panic("feedback can only be given after complete")
	}

	if contract.funder == caller.String() {
		contracts[contractId].funderFeedback = feedback
	} else if contract.contractor == caller.String() {
		contracts[contractId].contractorFeedback = feedback
	} else {
		panic("only contract participants can leave feedback")
	}
}

func GetContracts(startAfter, limit uint64) []Contract {
	max := uint64(len(contracts))
	if startAfter+limit < max {
		max = startAfter + limit
	}
	return contracts[startAfter:max]
}

func RenderContract(contractId uint64) string {
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	c := contracts[contractId]

	milestoneEncodes := []string{}
	for _, m := range c.milestones {
		milestoneEncodes = append(milestoneEncodes, fmt.Sprintf(`{
	"title": "%s",
	"amount": %d,
	"paid": %d,
	"duration": %d,
	"status": "%s",
	"funded": %t,
	"link": "%s"
}`, m.title, m.amount, m.paid, m.duration, m.status.String(), m.funded, m.link))
	}
	milestonesText := strings.Join(milestoneEncodes, ",\n")

	return fmt.Sprintf(`{
		"id": %d,
		"sender": "%s",
		"contractor": "%s",
		"funder": "%s",
		"escrowToken": "%s",
		"metadata": "%s",
		"status": "%s",
		"expireAt": %d,
		"funderFeedback": "%s",
		"contractorFeedback": "%s",
		"milestones": [%s],
		"activeMilestone": %d,
		"pausedBy": "%s",
		"conflictHandler": "%s",
		"handlerCandidate": "%s",
		"handlerSuggestor": "%s"
}`, c.id, c.sender, c.contractor, c.funder, c.escrowToken, c.metadata, c.status.String(),
		c.expireAt, c.funderFeedback, c.contractorFeedback,
		milestonesText, c.activeMilestone, c.pausedBy,
		c.conflictHandler, c.handlerCandidate, c.handlerSuggestor)
}

func RenderContracts(startAfter uint64, limit uint64) string {
	contracts := GetContracts(startAfter, limit)
	rendered := "["
	for index, contract := range contracts {
		rendered += RenderContract(contract.id)
		if index != len(contracts)-1 {
			rendered += ",\n"
		}
	}
	rendered += "]"
	return rendered
}
