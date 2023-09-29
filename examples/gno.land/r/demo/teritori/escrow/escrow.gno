package escrow

import (
	fmt "gno.land/p/demo/ufmt"
	"gno.land/r/demo/foo20"
	"gno.land/r/demo/users"
	"std"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	daoAdmin string
}

type ContractStatus uint32

const (
	CREATED   ContractStatus = 1
	ACCEPTED  ContractStatus = 2
	CANCELED  ContractStatus = 3
	PAUSED    ContractStatus = 4
	COMPLETED ContractStatus = 5
)

type Milestone struct {
	title    string
	amount   uint64
	paid     uint64
	duration uint64
	funded   bool
}

type Contract struct {
	id              uint64
	sender          string
	contractor      string
	funder          string // funder address
	escrowToken     string // grc20 token
	status          ContractStatus
	expireAt        uint64
	clientFeedback  string
	sellerFeedback  string
	milestones      []Milestone
	activeMilestone uint64
	pausedBy        string
}

// GNODAO STATE
var config Config
var contracts []Contract

// GNODAO FUNCTIONS
func UpdateConfig(daoAdmin string) {
	if config.daoAdmin == "" {
		config.daoAdmin = daoAdmin
		return
	}
	caller := std.GetOrigCaller()
	if config.daoAdmin != caller.String() {
		panic("not allowed to update daoAdmin")
	}

	config.daoAdmin = daoAdmin
}

func CurrentRealm() string {
	return std.CurrentRealm().Addr().String()
}

func CreateContract(
	contractor string,
	funder string,
	escrowToken string, // grc20 token
	expiryDuration uint64,
	milestoneTitles string,
	milestoneAmounts string,
	milestoneDurations string,
) {
	caller := std.GetOrigCaller()
	if expiryDuration == 0 {
		panic("invalid expiryDuration")
	}
	if escrowToken == "" {
		panic("invalid escrow token")
	}

	if contractor != caller.String() && funder != caller.String() {
		panic("caller should be one of contractor or funder")
	}

	milestoneTitleArr := strings.Split(milestoneTitles, ",")
	milestoneAmountArr := strings.Split(milestoneAmounts, ",")
	milestoneDurationArr := strings.Split(milestoneDurations, ",")

	if len(milestoneTitleArr) == 0 {
		panic("no milestone titles provided")
	}

	if len(milestoneTitleArr) != len(milestoneAmountArr) || len(milestoneTitleArr) != len(milestoneDurationArr) {
		panic("mismatch on milestones title, amount and duration")
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
			funded:   false,
		})
	}

	contractId := uint64(len(contracts))
	contracts = append(contracts, Contract{
		id:              contractId,
		sender:          caller.String(),
		contractor:      contractor,
		funder:          funder,
		escrowToken:     escrowToken,
		status:          CREATED,
		expireAt:        uint64(time.Now().Unix()) + expiryDuration,
		milestones:      milestones,
		activeMilestone: 0,
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

	if contract.sender != caller.String() {
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

	if contract.status == CREATED {
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

	foo20.Transfer(
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

	if contract.status == CREATED {
		panic("cannot pay on not accepted contract")
	}

	milestoneId := contract.activeMilestone
	milestone := contract.milestones[milestoneId]
	unpaid := milestone.amount - milestone.paid
	if unpaid > 0 {
		foo20.Transfer(
			users.AddressOrName(contract.contractor),
			unpaid)
		contracts[contractId].milestones[milestoneId].paid += unpaid
	}
	contracts[contractId].activeMilestone += 1
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
	foo20.TransferFrom(
		users.AddressOrName(caller.String()),
		users.AddressOrName(std.CurrentRealm().Addr().String()),
		milestone.amount)
	contracts[contractId].milestones[milestoneId].funded = true
}

func AddUpcomingMilestone(
	contractId uint64,
	title string,
	amount uint64,
	duration uint64,
) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.funder != caller.String() && contract.contractor != caller.String() {
		panic("only contract participants can add upcoming milestone")
	}

	contracts[contractId].milestones = append(contracts[contractId].milestones, Milestone{
		title:    title,
		amount:   amount,
		paid:     false,
		duration: duration,
		funded:   false,
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

	milestones := contract.milestones
	if len(milestones) <= int(milestoneId) {
		panic("milestone is not valid")
	}
	milestone := milestones[milestoneId]
	if milestone.funded {
		panic("cannot cancel funded milestone")
	}
	contract.milestones = append(milestones[:milestoneId], milestones[milestoneId+1:]...)
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

func CompleteContractByDAO(contractId uint64, sellerAmount uint64) {
	caller := std.GetOrigCaller()
	if int(contractId) >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != PAUSED {
		panic("contract can only be processed by DAO at PAUSED status")
	}

	if config.daoAdmin != caller.String() {
		panic("only dao admin is allowed for this operation")
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

	clientAmount := unpaidAmount - sellerAmount

	foo20.Transfer(
		users.AddressOrName(contract.contractor),
		sellerAmount)
	foo20.Transfer(
		users.AddressOrName(contract.funder),
		clientAmount)
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
		contracts[contractId].clientFeedback = feedback
	} else if contract.contractor == caller.String() {
		contracts[contractId].sellerFeedback = feedback
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

func RenderConfig() string {
	return fmt.Sprintf(`{
		"daoAdmin": "%s"
}`, config.daoAdmin)
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
	"funded": %t
}`, m.title, m.amount, m.paid, m.duration, m.funded))
	}
	milestonesText := strings.Join(milestoneEncodes, ",\n")

	return fmt.Sprintf(`{
		"id": %d,
		"sender": "%s",
		"contractor": "%s",
		"funder": "%s",
		"escrowToken": "%s",
		"status": %d,
		"expireAt": %d,
		"clientFeedback": "%s",
		"sellerFeedback": "%s",
		"milestones": [%s],
		"activeMilestone": %d,
		"pausedBy": "%s"
}`, c.id, c.sender, c.contractor, c.funder, c.escrowToken, int(c.status), c.expireAt, c.clientFeedback, c.sellerFeedback, milestonesText, c.activeMilestone, c.pausedBy)
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
