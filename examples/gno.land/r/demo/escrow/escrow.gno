package escrow

import (
	"gno.land/r/demo/foo20"
	fmt "gno.land/p/demo/ufmt"
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

type Contract struct {
	id            uint64
	sender        string
	receiver      string
	escrowToken   string // grc20 token
	escrowAmount  uint64
	status        ContractStatus
	expireAt      uint64
	clientFeedback string
	sellerFeedback string
}

// GNODAO STATE
var config Config
var contracts []Contract

// GNODAO FUNCTIONS
func UpdateConfig(daoAdmin string) {
	if daoAdmin == "" {
		config.daoAdmin = daoAdmin
		return
	}
	caller := std.GetOrigCaller()
	if config.daoAdmin != caller.String() {
		panic("not allowed to update daoAdmin")
	}

	config.daoAdmin = daoAdmin
}

func CreateContract(
	receiver     string
	escrowToken  string // grc20 token
	escrowAmount uint64
	duration     uint64
) {
	caller := std.GetOrigCaller()
	if duration == 0 {
		panic("invalid duration")
	}
	if escrowToken == "" {
		panic("invalid escrow token")
	}
	if escrowAmount == 0 {
		panic("invalid escrow amount")
	}

	contractId := uint64(len(contracts))
	contracts = append(contracts, Contract{
		id: contractId,
		sender: caller.String(),
		receiver: receiver,
		escrowToken: escrowToken,
		escrowAmount: escrowAmount,
		status: CREATED,
		expireAt: time.Now().Unix() + duration,
	})
	foo20.TransferFrom(sender, config.daoAdmin, escrowAmount)
}

func CancelContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
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

	// return grc20 tokens back to sender
	// TODO: resolve caller problem
	foo20.Transfer(sender, contract.escrowAmount)
}

func AcceptContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != CREATED {
		panic("contract can only be accepted at CREATED status")
	}

	if contract.expireAt < time.Now().Unix() {
		panic("contract already expired")
	}

	if contract.receiver != caller.String() {
		panic("only associated receiver is allowed to accept")
	}
	contracts[contractId].status = ACCEPTED
}

func PauseContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != ACCEPTED {
		panic("contract can only be paused at ACCEPTED status")
	}

	if contract.sender != caller.String() && contract.receiver != caller.String() {
		panic("only contract sender or receiver can pause")
	}
	contracts[contractId].status = PAUSED
}

func CompleteContract(contractId uint64) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != ACCEPTED {
		panic("contract can only be completed at ACCEPTED status")
	}

	if contract.sender != caller.String() {
		panic("only contract sender can complete")
	}

	// send tokens to receiver
	// TODO: resolve caller problem
	foo20.Transfer(receiver, contract.escrowAmount)
	contracts[contractId].status = COMPLETED
}

func CompleteContractByDAO(contractId uint64, sellerAmount uint64) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != PAUSED {
		panic("contract can only be processed by DAO at PAUSED status")
	}

	if config.daoAdmin != caller.String() {
		panic("only dao admin is allowed for this operation")
	}

	clientAmount := contract.escrowAmount - sellerAmount
	contracts[contractId].status = COMPLETED

	// send tokens for client and seller
	// TODO: resolve caller problem
	foo20.Transfer(contract.receiver, sellerAmount)
	foo20.Transfer(contract.sender, clientAmount)
}

func GiveFeedback(contractId uint64, feedback string) {
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	contract := contracts[contractId]
	if contract.status != COMPLETED {
		panic("feedback can only be given after complete")
	}

	if contract.sender == caller.String() {
		contracts[contractId].clientFeedback = feedback
	} else if contract.receiver == caller.String() {
		contracts[contractId].sellerFeedback = feedback
	} else {
		panic("only contract participants can leave feedback")
	}
}


func GetContracts(startAfter, limit uint64) []DAO {
	max := uint64(len(contracts))
	if startAfter+limit < max {
		max = startAfter + limit
	}
	return contracts[startAfter:max]
}

func RenderConfig() string {
	return fmt.Sprintf(`{
		"daoAdmin": %s
}`, config.daoAdmin)
}

func RenderContract(contractId uint64) string {	
	caller := std.GetOrigCaller()
	if contractId >= len(contracts) {
		panic("invalid contract id")
	}

	c := contracts[contractId]
	return fmt.Sprintf(`{
		"id": %d,
		"sender": "%s",
		"receiver": "%s",
		"escrowToken": "%s",
		"escrowAmount": %d,
		"status": %d,
		"expireAt": %d
}`, c.id, c.sender, c.receiver, c.escrowToken, c.escrowAmount, c.status, c.expireAt)
}

func RenderContracts(startAfter uint64, limit uint64) string {
	contracts := GetContracts(startAfter, limit)
	rendered := "["
	for index, proposal := range contracts {
		rendered += RenderContract(proposal.daoId, proposal.id)
		if index != len(contracts)-1 {
			rendered += ",\n"
		}
	}
	rendered += "]"
	return rendered
}