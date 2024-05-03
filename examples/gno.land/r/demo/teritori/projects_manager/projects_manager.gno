package projects_manager

import (
	"std"
	"strconv"
	"strings"
	"time"

	"gno.land/p/demo/json"
	"gno.land/p/demo/ufmt"
)

type ContractStatus uint32

const (
	CREATED                        ContractStatus = 1
	ACCEPTED                       ContractStatus = 2
	CANCELED                       ContractStatus = 3
	COMPLETED                      ContractStatus = 5
	REJECTED                       ContractStatus = 6
	CONFLICT                       ContractStatus = 7
	ABORTED_IN_FAVOR_OF_CONTRACTOR ContractStatus = 8
	ABORTED_IN_FAVOR_OF_FUNDER     ContractStatus = 9
)

func (x ContractStatus) String() string {
	switch x {
	case CREATED:
		return "CREATED"
	case ACCEPTED:
		return "ACCEPTED"
	case CANCELED:
		return "CANCELED"
	case COMPLETED:
		return "COMPLETED"
	case REJECTED:
		return "REJECTED"
	case CONFLICT:
		return "CONFLICT"
	case ABORTED_IN_FAVOR_OF_CONTRACTOR:
		return "ABORTED_IN_FAVOR_OF_CONTRACTOR"
	case ABORTED_IN_FAVOR_OF_FUNDER:
		return "ABORTED_IN_FAVOR_OF_FUNDER"
	}
	return "UNKNOWN"
}

func (x ContractStatus) ToJSON() *json.Node {
	return json.StringNode("", x.String())
}

type ConflictOutcome uint32

const (
	RESUME_CONTRACT ConflictOutcome = 1
	REFUND_FUNDER   ConflictOutcome = 2
	PAY_CONTRACTOR  ConflictOutcome = 3
)

func (x ConflictOutcome) String() string {
	switch x {
	case RESUME_CONTRACT:
		return "RESUME_CONTRACT"
	case REFUND_FUNDER:
		return "REFUND_FUNDER"
	case PAY_CONTRACTOR:
		return "PAY_CONTRACTOR"
	}
	return "UNKNOWN"
}

func (x ConflictOutcome) ToJSON() *json.Node {
	return json.StringNode("", x.String())
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

func (x MilestoneStatus) ToJSON() *json.Node {
	return json.StringNode("", x.String())
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

func (x MilestonePriority) ToJSON() *json.Node {
	return json.StringNode("", x.String())
}

type Milestone struct {
	id       uint64
	title    string
	desc     string
	amount   int64
	paid     int64
	duration time.Duration
	link     string // milestone reference link
	funded   bool
	priority MilestonePriority
	status   MilestoneStatus
}

func (ms Milestone) ToJSON() *json.Node {
	return json.ObjectNode("", map[string]*json.Node{
		"id":       json.StringNode("", strconv.FormatUint(ms.id, 10)),
		"title":    json.StringNode("", ms.title),
		"desc":     json.StringNode("", ms.desc),
		"amount":   json.StringNode("", strconv.FormatInt(ms.amount, 10)),
		"paid":     json.StringNode("", strconv.FormatInt(ms.paid, 10)),
		"duration": json.NumberNode("", ms.duration.Seconds()),
		"link":     json.StringNode("", ms.link),
		"funded":   json.BoolNode("", ms.funded),
		"priority": ms.priority.ToJSON(),
		"status":   ms.status.ToJSON(),
	})
}

type Conflict struct {
	initiator         std.Address
	createdAt         time.Time
	respondedAt       *time.Time
	resolvedAt        *time.Time
	initiatorMessage  string
	responseMessage   *string
	resolutionMessage *string
	outcome           *ConflictOutcome
}

func (c Conflict) ToJSON() *json.Node {
	children := map[string]*json.Node{
		"initiator":        json.StringNode("", c.initiator.String()),
		"createdAt":        json.StringNode("", c.createdAt.Format(time.RFC3339)),
		"initiatorMessage": json.StringNode("", c.initiatorMessage),
	}

	if c.responseMessage != nil {
		children["responseMessage"] = json.StringNode("", *c.responseMessage)
	}
	if c.respondedAt != nil {
		children["respondedAt"] = json.StringNode("", c.respondedAt.Format(time.RFC3339))
	}
	if c.resolvedAt != nil {
		children["resolvedAt"] = json.StringNode("", c.resolvedAt.Format(time.RFC3339))
	}
	if c.resolutionMessage != nil {
		children["resolutionMessage"] = json.StringNode("", *c.resolutionMessage)
	}
	if c.outcome != nil {
		children["outcome"] = c.outcome.ToJSON()
	}

	return json.ObjectNode("", children)
}

type Contract struct {
	id                   uint64
	sender               std.Address
	contractor           std.Address
	contractorCandidates []std.Address
	funder               std.Address // funder address
	paymentDenom         string      // banker denom
	metadata             string      // store data forforimage, tags, name, description, links for twitter/github...
	status               ContractStatus
	expireAt             time.Time
	funderFeedback       string
	contractorFeedback   string
	milestones           []Milestone
	pausedBy             string
	conflictHandler      string // can be a realm path or a caller address
	handlerCandidate     string // conflict handler candidate suggested by one party
	handlerSuggestor     string // the suggestor off the conflict handler candidate
	createdAt            time.Time
	budget               int64
	funded               bool
	rejectReason         string
	conflicts            []Conflict
}

func (c Contract) ToJSON() *json.Node {
	candidates := make([]*json.Node, len(c.contractorCandidates))
	for i, candidate := range c.contractorCandidates {
		candidates[i] = json.StringNode("", candidate.String())
	}

	milestones := make([]*json.Node, len(c.milestones))
	for i, milestone := range c.milestones {
		milestones[i] = milestone.ToJSON()
	}

	conflicts := make([]*json.Node, len(c.conflicts))
	for i, conflict := range c.conflicts {
		conflicts[i] = conflict.ToJSON()
	}

	return json.ObjectNode("", map[string]*json.Node{
		"id":                   json.StringNode("", strconv.FormatUint(c.id, 10)),
		"sender":               json.StringNode("", c.sender.String()),
		"contractor":           json.StringNode("", c.contractor.String()),
		"contractorCandidates": json.ArrayNode("", candidates),
		"funder":               json.StringNode("", c.funder.String()),
		"paymentDenom":         json.StringNode("", c.paymentDenom),
		"metadata":             json.StringNode("", c.metadata),
		"status":               c.status.ToJSON(),
		"expireAt":             json.StringNode("", c.expireAt.Format(time.RFC3339)),
		"funderFeedback":       json.StringNode("", c.funderFeedback),
		"contractorFeedback":   json.StringNode("", c.contractorFeedback),
		"milestones":           json.ArrayNode("", milestones),
		"pausedBy":             json.StringNode("", c.pausedBy),
		"conflictHandler":      json.StringNode("", c.conflictHandler),
		"handlerCandidate":     json.StringNode("", c.handlerCandidate),
		"handlerSuggestor":     json.StringNode("", c.handlerSuggestor),
		"createdAt":            json.StringNode("", c.createdAt.Format(time.RFC3339)),
		"budget":               json.StringNode("", strconv.FormatInt(c.budget, 10)),
		"funded":               json.BoolNode("", c.funded),
		"rejectReason":         json.StringNode("", c.rejectReason),
		"conflicts":            json.ArrayNode("", conflicts),
	})
}

// Escrow State
var contracts []Contract

func CurrentRealm() string {
	return std.CurrentRealm().Addr().String()
}

func CreateContract(
	contractor std.Address,
	funder std.Address,
	paymentDenom string,
	metadata string,
	expiryDurationSeconds uint64,
	milestoneTitles string,
	milestoneDescs string,
	milestoneAmounts string,
	milestoneDurationsSeconds string,
	milestoneLinks string,
	milestonePriorities string,
	conflictHandler string,
) {
	if contractor != "" && !contractor.IsValid() {
		panic("invalid contractor address")
	}

	if funder != "" && !funder.IsValid() {
		panic("invalid funder address")
	}

	caller := std.PrevRealm().Addr()
	if expiryDurationSeconds == 0 {
		panic("invalid expiryDuration")
	}
	if paymentDenom == "" {
		panic("empty escrow token")
	}

	// For now, one of funder or contract could be empty and can be set later
	if contractor == "" && funder == "" {
		panic("contractor and funder cannot be both empty")
	}

	if contractor != caller && funder != caller {
		panic("caller should be one of contractor or funder")
	}

	milestoneTitleArr := strings.Split(milestoneTitles, ",")
	milestoneDescArr := strings.Split(milestoneDescs, ",")
	milestoneAmountArr := strings.Split(milestoneAmounts, ",")
	milestoneDurationArr := strings.Split(milestoneDurationsSeconds, ",")
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
	projectBudget := int64(0)
	for i, title := range milestoneTitleArr {
		amount, err := strconv.Atoi(milestoneAmountArr[i])
		if err != nil {
			panic(err)
		}
		if amount < 0 {
			panic("milestone amount should be a positive number")
		}

		durationSeconds, err := strconv.Atoi(milestoneDurationArr[i])
		if err != nil {
			panic(err)
		}
		if durationSeconds <= 0 {
			panic("milestone duration should be greater than 0")
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

		duration := time.Duration(durationSeconds) * time.Second

		milestones = append(milestones, Milestone{
			id:       uint64(i),
			title:    title,
			desc:     milestoneDescArr[i],
			amount:   int64(amount),
			paid:     0,
			duration: duration,
			link:     milestoneLinkArr[i],
			priority: prio,
			funded:   false,
			status:   MS_OPEN,
		})
		projectBudget += int64(amount)
	}

	// If contract creator is funder then he needs to send all the needed fund to contract
	funded := false
	if caller == funder {
		sent := std.GetOrigSend()
		amount := sent.AmountOf(paymentDenom)
		if amount != projectBudget {
			panic("funder should send all the needed funds at instantiation")
		}
		funded = true
	}

	expiryDuration := time.Duration(expiryDurationSeconds) * time.Second
	now := time.Now()

	contractId := uint64(len(contracts))
	contracts = append(contracts, Contract{
		id:              contractId,
		sender:          caller,
		contractor:      contractor,
		funder:          funder,
		paymentDenom:    paymentDenom,
		metadata:        metadata,
		status:          CREATED,
		expireAt:        now.Add(expiryDuration),
		milestones:      milestones,
		conflictHandler: conflictHandler,
		budget:          projectBudget,
		createdAt:       now,
		funded:          funded,
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

	if contract.sender != caller {
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

	if contract.sender == contract.contractor && caller != contract.funder {
		// If contract creator is contractor then only funder can reject
		panic("only funder can reject a request from contractor")
	} else if contract.sender == contract.funder && caller != contract.contractor {
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

	if time.Now().After(contract.expireAt) {
		panic("contract already expired")
	}

	if contract.sender == caller {
		panic("contract sender is not able to accept the contract")
	}

	if contract.funder != caller && contract.contractor != caller {
		panic("only contract counterparty is allowed to accept")
	}
	contracts[contractId].status = ACCEPTED
}

// Submit a funder by putting funds for specific milestones
func SubmitFunder(contractId uint64) {
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

	if caller == contract.contractor {
		panic("you cannot become a funder of your requested contract")
	}

	sent := std.GetOrigSend()
	amount := sent.AmountOf(contract.paymentDenom)
	if amount != contract.budget {
		panic("wrong amount of funds sent")
	}

	contracts[contractId].funded = true
	contracts[contractId].status = ACCEPTED
	contracts[contractId].funder = caller
}

// Accept candidate as a contractor
func AcceptContractor(contractId uint64, contractor std.Address) {
	if !contractor.IsValid() {
		panic("invalid contractor address")
	}

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

	if caller != contract.funder {
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

	if caller == contract.funder {
		panic("you cannot become a contractor of your funded contract")
	}

	candidates := contracts[contractId].contractorCandidates
	for _, candidate := range candidates {
		if candidate == caller {
			panic("already a contractor candidate")
		}
	}

	contracts[contractId].contractorCandidates = append(candidates, caller)
}

// Complete any milestone in review status and pay the needed amount
func CompleteMilestoneAndPay(contractId uint64, milestoneId uint64) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller {
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
		banker := std.GetBanker(std.BankerTypeRealmSend)
		banker.SendCoins(
			std.CurrentRealm().Addr(),
			contract.contractor,
			std.Coins{std.Coin{contract.paymentDenom, int64(unpaid)}})
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
	if newStatus == MS_COMPLETED {
		panic("use CompleteMilestoneAndPay to complete and pay the milestone")
	}

	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}
	contract := contracts[contractId]

	caller := std.PrevRealm().Addr()
	if contract.funder != caller && contract.contractor != caller {
		panic("only contract participant can execute the action")
	}

	if contract.status != ACCEPTED {
		panic("contract is not on accepted status")
	}

	if len(contract.milestones) <= milestoneId {
		panic("milestone Id does not exist in contract")
	}
	milestone := contract.milestones[milestoneId]

	if milestone.status == MS_COMPLETED {
		panic("milestone is completed")
	}

	contracts[contractId].milestones[milestoneId].status = newStatus
}

func RequestConflictResolution(contractId uint64, message string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller && contract.contractor != caller {
		panic("only contract participants can request conflict resolution")
	}

	if contract.status != ACCEPTED {
		panic("conflict resolution can only be requested at ACCEPTED status")
	}

	contracts[contractId].status = CONFLICT

	contracts[contractId].conflicts = append(contract.conflicts, Conflict{
		initiator:        caller,
		createdAt:        time.Now(),
		initiatorMessage: message,
	})
}

func RespondToConflict(contractId uint64, message string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != CONFLICT {
		panic("conflict can only be responded at CONFLICT status")
	}

	if len(contract.conflicts) == 0 {
		panic("no conflict exists, this should not happen")
	}

	conflictId := len(contract.conflicts) - 1
	conflict := contract.conflicts[conflictId]

	if conflict.initiator == contract.funder {
		if contract.contractor != caller {
			panic("only contract funder can respond to this conflict")
		}
	} else if conflict.initiator == contract.contractor {
		if contract.funder != caller {
			panic("only contract contractor can respond to this conflict")
		}
	} else {
		panic("conflict initiator is not valid")
	}

	contracts[contractId].conflicts[conflictId].responseMessage = &message
	now := time.Now()
	contracts[contractId].conflicts[conflictId].respondedAt = &now
}

func ResolveConflict(contractId uint64, outcome ConflictOutcome, resolutionMessage string) {
	caller := std.PrevRealm().Addr()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.conflictHandler != caller.String() {
		panic("only conflictHandler is allowed for this operation")
	}

	if contract.status != CONFLICT {
		panic("conflict can only be resolved at CONFLICT status")
	}

	if len(contract.conflicts) == 0 {
		panic("no conflict exists")
	}

	conflictId := len(contract.conflicts) - 1

	switch outcome {
	case RESUME_CONTRACT:
		contracts[contractId].status = ACCEPTED
	case REFUND_FUNDER:
		totalPaid := int64(0)
		for _, milestone := range contract.milestones {
			totalPaid += milestone.paid
		}
		banker := std.GetBanker(std.BankerTypeRealmSend)
		banker.SendCoins(
			std.CurrentRealm().Addr(),
			contract.funder,
			std.Coins{std.Coin{contract.paymentDenom, contract.budget - totalPaid}})
		contracts[contractId].status = ABORTED_IN_FAVOR_OF_FUNDER
	case PAY_CONTRACTOR:
		totalPaid := int64(0)
		for _, milestone := range contract.milestones {
			totalPaid += milestone.paid
		}
		banker := std.GetBanker(std.BankerTypeRealmSend)
		banker.SendCoins(
			std.CurrentRealm().Addr(),
			contract.contractor,
			std.Coins{std.Coin{contract.paymentDenom, contract.budget - totalPaid}})
		contracts[contractId].status = ABORTED_IN_FAVOR_OF_CONTRACTOR
	default:
		panic("invalid outcome")
	}

	contracts[contractId].conflicts[conflictId].resolutionMessage = &resolutionMessage
	contracts[contractId].conflicts[conflictId].outcome = &outcome
	now := time.Now()
	contracts[contractId].conflicts[conflictId].resolvedAt = &now
}

func GetContractorCandidatesJSON(contractId uint64) string {
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	candidates := contracts[contractId].contractorCandidates
	candidatesJSON := make([]*json.Node, len(candidates))
	for i, candidate := range candidates {
		candidatesJSON[i] = json.StringNode("", candidate.String())
	}

	ret, err := json.Marshal(json.ArrayNode("", candidatesJSON))
	if err != nil {
		panic(err)
	}
	return string(ret)
}

func GetContracts(startAfter, limit uint64, filterByFunder string, filterByContractor string) []Contract {
	max := uint64(len(contracts))
	if startAfter+limit < max {
		max = startAfter + limit
	}

	var results []Contract
	i := uint64(0)

	for _, c := range contracts {
		if filterByFunder != "ALL" && c.funder.String() != filterByFunder {
			continue
		}

		if filterByContractor != "ALL" && c.contractor.String() != filterByContractor {
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

func RenderContractJSON(contractId uint64) string {
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	c := contracts[contractId]
	ret, err := json.Marshal(c.ToJSON())
	if err != nil {
		panic(err)
	}

	return string(ret)
}

func RenderContractsJSON(startAfter uint64, limit uint64, filterByFunder string, filterByContractor string) string {
	contracts := GetContracts(startAfter, limit, filterByFunder, filterByContractor)
	contractsJSON := make([]*json.Node, len(contracts))
	for i, c := range contracts {
		contractsJSON[i] = c.ToJSON()
	}

	ret, err := json.Marshal(json.ArrayNode("", contractsJSON))
	if err != nil {
		panic(err)
	}
	return string(ret)
}

func Render(path string) string {
	b := strings.Builder{}
	b.WriteString("# Projects Manager\n")
	b.WriteString("## Overview\n")
	b.WriteString("This contract is a simple project manager that allows users to create projects and manage them.\n")
	b.WriteString(ufmt.Sprintf("Contracts managed: %d\n", len(contracts)))
	b.WriteString("## Latest projects\n")
	numContracts := 3
	if len(contracts) < 3 {
		numContracts = len(contracts)
	}
	for i := 0; i < numContracts; i++ {
		b.WriteString("```json\n")
		b.WriteString(RenderContractJSON(uint64(len(contracts) - (i + 1))))
		b.WriteString("\n")
		b.WriteString("```\n")
	}
	return b.String()
}
