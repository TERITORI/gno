package escrow

import (
	"std"
	"strconv"
	"strings"
	"time"

	token_registry "gno.land/p/demo/teritori/token_registry_02"
	fmt "gno.land/p/demo/ufmt"
	"gno.land/r/demo/users"
)

type ContractStatus uint32

const (
	CREATED   ContractStatus = 1
	ACCEPTED  ContractStatus = 2
	CANCELED  ContractStatus = 3
	PAUSED    ContractStatus = 4
	COMPLETED ContractStatus = 5
	REJECTED  ContractStatus = 6
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
	case REJECTED:
		return "REJECTED"
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

type MilestonePriority uint32

const (
	MS_PRIORITY_HIGH   MilestonePriority = 1
	MS_PRIORITY_MEDIUM MilestonePriority = 2
	MS_PRIORITY_LOW    MilestonePriority = 3
)

func (x MilestonePriority) String() string {
	switch x {
	case MS_PRIORITY_HIGH:
		return "MS_PRIORITY_HIGH"
	case MS_PRIORITY_MEDIUM:
		return "MS_PRIORITY_MEDIUM"
	case MS_PRIORITY_LOW:
		return "MS_PRIORITY_LOW"
	}
	return "UNKNOWN"
}

type Milestone struct {
	id       uint64
	title    string
	desc     string
	amount   uint64
	paid     uint64
	duration uint64
	link     string // milestone reference link
	funded   bool
	priority MilestonePriority
	status   MilestoneStatus
}

type Contract struct {
	id                   uint64
	sender               string
	contractor           string
	contractorCandidates []string
	funder               string // funder address
	escrowToken          string // grc20 token
	metadata             string // store data forforimage, tags, name, description, links for twitter/github...
	status               ContractStatus
	expireAt             uint64
	funderFeedback       string
	contractorFeedback   string
	milestones           []Milestone
	pausedBy             string
	conflictHandler      string // can be a realm path or a caller address
	handlerCandidate     string // conflict handler candidate suggested by one party
	handlerSuggestor     string // the suggestor off the conflict handler candidate
	createdAt            uint64
	budget               uint64
	funded               bool
	rejectReason         string
}

// Escrow State
var contracts []Contract
var token_reg = token_registry.New(CurrentRealm())

func CurrentRealm() string {
	return std.CurrentRealm().Addr().String()
}

func CreateContract(
	contractor string,
	funder string,
	escrowToken string,
	metadata string,
	expiryDuration uint64,
	milestoneTitles string,
	milestoneDescs string,
	milestoneAmounts string,
	milestoneDurations string,
	milestoneLinks string,
	milestonePriorities string,
	conflictHandler string,
) {
	caller := std.PrevRealm().Addr()
	if expiryDuration == 0 {
		panic("invalid expiryDuration")
	}
	if escrowToken == "" {
		panic("invalid escrow token")
	}

	// For now, one of funder or contract could be empty and can be set later
	if contractor == "" && funder == "" {
		panic("contractor and funder cannot be both empty")
	}

	if contractor != caller.String() && funder != caller.String() {
		panic("caller should be one of contractor or funder")
	}

	milestoneTitleArr := strings.Split(milestoneTitles, ",")
	milestoneDescArr := strings.Split(milestoneDescs, ",")
	milestoneAmountArr := strings.Split(milestoneAmounts, ",")
	milestoneDurationArr := strings.Split(milestoneDurations, ",")
	milestoneLinkArr := strings.Split(milestoneLinks, ",")
	milestonePrioritiesArr := strings.Split(milestonePriorities, ",")

	if len(milestoneTitleArr) == 0 {
		panic("no milestone titles provided")
	}

	if len(milestoneTitleArr) != len(milestoneAmountArr) ||
		len(milestoneTitleArr) != len(milestoneDurationArr) ||
		len(milestoneTitleArr) != len(milestonePrioritiesArr) ||
		len(milestoneTitleArr) != len(milestoneDescArr) ||
		len(milestoneTitleArr) != len(milestoneLinkArr) {
		panic("mismatch on milestones title, description, amount, duration, priority and link")
	}

	milestones := []Milestone{}
	projectBudget := uint64(0)
	for i, title := range milestoneTitleArr {
		amount, err := strconv.Atoi(milestoneAmountArr[i])
		if err != nil {
			panic(err)
		}
		duration, err := strconv.Atoi(milestoneDurationArr[i])
		if err != nil {
			panic(err)
		}

		var prio MilestonePriority

		switch milestonePrioritiesArr[i] {
		case "MS_PRIORITY_HIGH":
			prio = MS_PRIORITY_HIGH
		case "MS_PRIORITY_MEDIUM":
			prio = MS_PRIORITY_MEDIUM
		case "MS_PRIORITY_LOW":
			prio = MS_PRIORITY_LOW
		default:
			panic("priority is not valid")
		}

		milestones = append(milestones, Milestone{
			id:       uint64(i),
			title:    title,
			desc:     milestoneDescArr[i],
			amount:   uint64(amount),
			paid:     false,
			duration: uint64(duration),
			link:     milestoneLinkArr[i],
			priority: prio,
			funded:   false,
			status:   MS_OPEN,
		})
		projectBudget += uint64(amount)
	}

	// If contract creator is funder then he needs to send all the needed fund to contract
	funded := false
	if caller.String() == funder {
		token_reg.TransferFromByInterfaceName(
			contract.escrowToken,
			users.AddressOrName(caller.String()),
			users.AddressOrName(std.CurrentRealm().Addr().String()),
			projectBudget)

		funded = true
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
		conflictHandler: conflictHandler,
		budget:          projectBudget,
		funded:          funded,
		createdAt:       uint64(time.Now().Unix()),
	})
}

func CancelContract(contractId uint64) {
	caller := std.PrevRealm().Addr()
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

func RejectContract(contractId uint64, rejectReason string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != CREATED {
		panic("contract can only be cancelled at CREATED status")
	}

	if contract.sender == contract.contractor && caller.String() != contract.funder {
		// If contract creator is contractor then only funder can reject
		panic("only funder can reject a request from contractor")
	} else if contract.sender == contract.funder && caller.String() != contract.contractor {
		// If contract creator is funder then only contractor can reject
		panic("only contractor can reject a request from funder")
	}

	contracts[contractId].status = REJECTED
	contracts[contractId].rejectReason = rejectReason
}

func AcceptContract(contractId uint64) {
	caller := std.PrevRealm().Addr()
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
	caller := std.PrevRealm().Addr()
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
	caller := std.PrevRealm().Addr()
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

// pay partial amount for the milestone
func PayPartialMilestone(contractId uint64, milestoneId uint64, amount uint64) {
	caller := std.PrevRealm().Addr()
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

	milestone := contract.milestones[milestoneId]
	if !milestone.funded {
		panic("not funded for the milestone")
	}
	if milestone.paid+amount > milestone.amount {
		panic("could not pay more than milestone amount")
	}

	token_reg.TransferByInterfaceName(
		contract.escrowToken,
		users.AddressOrName(contract.contractor),
		amount)
	contracts[contractId].milestones[milestoneId].paid += amount
}

// Submit a funder by putting funds for specific milestones
func SubmitFunder(contractId uint64, fundingMilestoneIds string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]

	if contract.status != CREATED {
		panic("can only submit candidate to a CREATED contract")
	}

	if contract.funder != "" {
		panic("the contract has already a funder")
	}

	if caller.String() == contract.contractor {
		panic("you cannot become a funder of your requested contract")
	}

	milestoneIdsAddr := strings.Split(fundingMilestoneIds, ",")
	if fundingMilestoneIds == "" {
		panic("should fund at least one milestone when submitting a funder")
	}

	// Deposit needed amount to contract to become funder
	budget := uint64(0)
	for _, milestoneIdStr := range milestoneIdsAddr {
		milestoneId, err := strconv.Atoi(milestoneIdStr)
		if err != nil {
			panic(err)
		}
		if milestoneId >= len(contract.milestones) || milestoneId < 0 {
			panic("invalid milestoneId")
		}
		milestone := contract.milestones[milestoneId]
		budget += milestone.amount
	}

	token_reg.TransferFromByInterfaceName(
		contract.escrowToken,
		users.AddressOrName(caller.String()),
		users.AddressOrName(std.CurrentRealm().Addr().String()),
		budget,
	)

	contracts[contractId].funded = true
	contracts[contractId].status = ACCEPTED
	contracts[contractId].funder = caller.String()
}

// Accept candidate as a contractor
func AcceptContractor(contractId uint64, contractor string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]

	if contract.status != CREATED {
		panic("can only submit candidate to a CREATED contract")
	}

	if contract.contractor != "" {
		panic("the contract has already a contractor")
	}

	if caller.String() != contract.funder {
		panic("Only contract funder can accept contractor")
	}

	candidates := contracts[contractId].contractorCandidates
	for _, candidate := range candidates {
		// Accept the contract if the address already submitted candidate request
		if candidate == contractor {
			contracts[contractId].status = ACCEPTED
		}
	}

	contracts[contractId].contractor = contractor
}

func SubmitContractorCandidate(contractId uint64) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]

	if contract.status != CREATED {
		panic("can only submit candidate to a CREATED contract")
	}

	if contract.contractor != "" {
		panic("the contract has already a contractor")
	}

	if caller.String() == contract.funder {
		panic("you cannot become a contractor of your funded contract")
	}

	candidates := contracts[contractId].contractorCandidates
	for _, candidate := range candidates {
		if candidate == caller.String() {
			panic("already a contractor candidate")
		}
	}

	contracts[contractId].contractorCandidates = append(candidates, caller.String())
}

// Complete any milestone in review status and pay the needed amount
func CompleteMilestoneAndPay(contractId uint64, milestoneId uint64) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() {
		panic("only contract funder can pay the milestone")
	}

	if contract.status != ACCEPTED {
		panic("only accepted contract can be paid")
	}

	milestone := contract.milestones[milestoneId]
	if milestone.status != MS_REVIEW {
		panic("can only complete and pay a milestone which is in review status")
	}

	// Pay the milestone
	unpaid := milestone.amount - milestone.paid
	if unpaid > 0 {
		token_reg.TransferByInterfaceName(
			contract.escrowToken,
			users.AddressOrName(contract.contractor),
			unpaid)
		contracts[contractId].milestones[milestoneId].paid += unpaid
	}

	contracts[contractId].milestones[milestoneId].status = MS_COMPLETED

	// If finish all milestone then complete the contract
	completedCount := 0
	for _, milestone := range contract.milestones {
		if milestone.status == MS_COMPLETED {
			completedCount++
		}
	}

	if completedCount == len(contract.milestones) {
		contracts[contractId].status = COMPLETED
	}
}

// Set milestone status
func ChangeMilestoneStatus(contractId uint64, milestoneId int, newStatus MilestoneStatus) {
	caller := std.PrevRealm().Addr()
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

	if caller.String() == contract.contractor && newStatus == MS_COMPLETED {
		panic("contractor cannot set status to completed")
	}

	if len(contract.milestones) <= milestoneId {
		panic("milestone Id does not exist in contract")
	}

	milestone := contract.milestones[milestoneId]
	if milestone.status == MS_COMPLETED {
		panic("milestone is already completed")
	}

	// Send fund when funder set project to completed
	if newStatus == MS_COMPLETED {
		// Pay the milestone
		unpaid := milestone.amount - milestone.paid
		if unpaid > 0 {
			token_reg.TransferByInterfaceName(
				contract.escrowToken,
				users.AddressOrName(contract.contractor),
				unpaid)
			contracts[contractId].milestones[milestoneId].paid += unpaid
		}
	}
	contracts[contractId].milestones[milestoneId].status = newStatus
}

// fund milestone
func FundMilestone(contractId uint64, milestoneId uint64) {
	caller := std.PrevRealm().Addr()
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

	if len(contract.milestones) <= int(milestoneId) {
		panic("invalid milestone id")
	}
	milestone := contract.milestones[milestoneId]
	if milestone.funded {
		panic("milestone already funded")
	}
	token_reg.TransferFromByInterfaceName(
		contract.escrowToken,
		users.AddressOrName(caller.String()),
		users.AddressOrName(std.CurrentRealm().Addr().String()),
		milestone.amount)
	contracts[contractId].milestones[milestoneId].funded = true
	contracts[contractId].milestones[milestoneId].status = MS_PROGRESS
}

func AddUpcomingMilestone(
	contractId uint64,
	title string,
	desc string,
	amount uint64,
	duration uint64,
	link string,
) {
	caller := std.PrevRealm().Addr()
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

	newId := len(contracts[contractId].milestones)

	contracts[contractId].milestones = append(contracts[contractId].milestones, Milestone{
		id:       uint64(newId),
		title:    title,
		desc:     desc,
		amount:   amount,
		paid:     false,
		duration: duration,
		funded:   false,
		status:   MS_OPEN,
	})
}

func CancelUpcomingMilestone(contractId uint64, milestoneId uint64) {
	caller := std.PrevRealm().Addr()
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
	caller := std.PrevRealm().Addr()
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

	for _, milestone := range contract.milestones {
		if milestone.status != MS_COMPLETED && milestone.funded {
			panic("active milestone exists")
		}
	}

	contracts[contractId].status = COMPLETED
}

func SuggestConflictHandler(contractId uint64, conflictHandler string) {
	caller := std.PrevRealm().Addr()
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
	caller := std.PrevRealm().Addr()
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

func CompleteContractByConflictHandler(contractId uint64, milestoneId uint64, contractorAmount uint64) {
	caller := std.PrevRealm().Addr()
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
	if len(milestones) <= int(milestoneId) {
		panic("active milestone is not valid")
	}
	milestone := milestones[milestoneId]
	if !milestone.funded {
		panic("milestone should be funded")
	}
	unpaidAmount := milestone.amount - milestone.paid

	funderAmount := unpaidAmount - contractorAmount

	token_reg.TransferByInterfaceName(
		contract.escrowToken,
		users.AddressOrName(contract.contractor),
		contractorAmount)
	token_reg.TransferByInterfaceName(
		contract.escrowToken,
		users.AddressOrName(contract.funder),
		funderAmount)

	contracts[contractId].milestones[milestoneId].paid += contractorAmount
	contracts[contractId].milestones[milestoneId].status = MS_COMPLETED

	canComplete := true
	for _, milestone := range contract.milestones {
		if milestone.funded && milestone.status != MS_COMPLETED {
			canComplete = false
		}
	}

	if canComplete {
		contracts[contractId].status = COMPLETED
	}
}

func GiveFeedback(contractId uint64, feedback string) {
	caller := std.PrevRealm().Addr()
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

func GetContracts(startAfter, limit uint64, filterByFunder string, filterByContractor string) []Contract {
	max := uint64(len(contracts))
	if startAfter+limit < max {
		max = startAfter + limit
	}

	var results []Contract
	i := uint64(0)

	for _, c := range contracts {
		if filterByFunder != "ALL" && c.funder != filterByFunder {
			continue
		}

		if filterByContractor != "ALL" && c.contractor != filterByContractor {
			continue
		}

		if i < startAfter {
			i++
			continue
		}

		if i > max {
			break
		}

		results = append(results, c)
		i++
	}

	return results
}

func RenderContract(contractId uint64) string {
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	c := contracts[contractId]

	milestoneEncodes := []string{}
	for _, m := range c.milestones {
		milestoneEncodes = append(milestoneEncodes, fmt.Sprintf(`{
	"id": %d,
	"title": "%s",
	"desc": "%s",
	"amount": %d,
	"paid": %d,
	"duration": %d,
	"status": "%s",
	"funded": %t,
	"priority": "%s",
	"link": "%s"
}`, m.id, m.title, m.desc, m.amount, m.paid, m.duration, m.status.String(), m.funded, m.priority.String(), m.link))
	}
	milestonesText := strings.Join(milestoneEncodes, ",\n")

	contractorCandidates = []string{}
	for _, candidate := range c.contractorCandidates {
		contractorCandidates = append(contractorCandidates, "\""+candidate+"\"")
	}
	contractorCandidatesText = strings.Join(contractorCandidates, ",")

	return fmt.Sprintf(`{
		"id": %d,
		"sender": "%s",
		"contractor": "%s",
		"contractorCandidates": [%s],
		"funder": "%s",
		"escrowToken": "%s",
		"metadata": "%s",
		"status": "%s",
		"expireAt": %d,
		"funderFeedback": "%s",
		"contractorFeedback": "%s",
		"milestones": [%s],
		"pausedBy": "%s",
		"conflictHandler": "%s",
		"handlerCandidate": "%s",
		"handlerSuggestor": "%s",
		"budget": %d,
		"funded": %t,
		"rejectReason": "%s"
}`, c.id, c.sender, c.contractor, contractorCandidatesText, c.funder, c.escrowToken, strings.ReplaceAll(c.metadata, "\"", "\\\""), c.status.String(),
		c.expireAt, c.funderFeedback, c.contractorFeedback,
		milestonesText, c.pausedBy,
		c.conflictHandler, c.handlerCandidate, c.handlerSuggestor, c.budget, c.funded, c.rejectReason)
}

func RenderContracts(startAfter uint64, limit uint64, filterByFunder string, filterByContractor string) string {
	contracts := GetContracts(startAfter, limit, filterByFunder, filterByContractor)
	rendered := "["
	for index, contract := range contracts {
		// If render === "[", it means we are first item => do not add separator
		if rendered != "[" {
			rendered += ",\n"
		}

		rendered += RenderContract(contract.id)
	}
	rendered += "]"
	return rendered
}

func RegisterGRC20Interface(token string, igrc20 GRC20Interface) {
	token_reg.RegisterGRC20Interface(token, igrc20)
}

func UnregisterToken(token string) {
	token_reg.UnregisterToken(token)
}

func RegisterBankToken(denom string) {
	token_reg.RegisterBankToken(denom)
}

func RealmAddr() string {
	realmAddr := std.GetOrigPkgAddr()
	return realmAddr.String()
}
