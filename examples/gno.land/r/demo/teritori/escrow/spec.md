# Escrow contract specification

## Data structure

### Contract Status

- `CREATED`: Status when one of the contract participant created offered a contract on-chain
- `ACCEPTED`: Status when the other participant accepted the contract and when the contract is established
- `CANCELED`: Status when the offer is cancelled by the party who created the offer.
- `PAUSED`: Status when the contract is paused by one of the contract participants.
- `COMPLETED`: Status when the contract has been completed. It can be completed by funder or when there's conflict, conflict solver realm could set the status to `COMPLETED` after resolving conflict.

### Milestone

```go
type Milestone struct {
	title    string
	amount   uint64
	paid     uint64
	duration uint64
	funded   bool
}
```

Milestone consists of `title`, `amount`, `paid`, `duration`, `funded`.

### Contract

```go
type Contract struct {
	id               uint64
	sender           string
	contractor       string
	funder           string // funder address
	escrowToken      string // grc20 token
	status           ContractStatus
	expireAt         uint64
	clientFeedback   string
	sellerFeedback   string
	milestones       []Milestone
	activeMilestone  uint64
	pausedBy         string
	conflictHandler  string // can be a realm path or a caller address
	handlerCandidate string // conflict handler candidate suggested by one party
	handlerSuggestor string // the suggestor off the conflict handler candidate
}
```

`Contract` is the contract representation between funder and contractor.

It has following fields

- `id` is the unique identifier of the contract
- `sender` is the party that has offered the contract can be either `funder` or `contractor`
- `funder` is a customer that pays for contractor's work.
- `contractor` is the party that takes care of the work that the customer needs or that is helpful to the customer
- `status` is the status of the contract.
- `expireAt` is the expected time when the offer will be expired if not accepted during the time
- `clientFeedback` is the feedback that the contractor has received from the funder after the contract completion
- `sellerFeedback` is the feedback that the funder has received from the contractor after the contract completion
- `milestones` is the milestones to be delievered as part of the contract
- `activeMilestone` refers to the index of milestone that is active now
- `pausedBy` is the field that records the party that paused the contract
- `conflictHandler` is the agreed address or realm path that will resolve the conflict between two parties
- `handlerCandidate` is the conflictHandler candidate suggested by one of funder or contractor
- `handlerSuggestor` is the address that suggested the latest `handlerCandidate`

## Endpoints

### Transactions

#### CreateContract

`CreateContract` is a process of offering a contract to the other party.

- As part of the offer, `contractor`, `funder`, `escrowToken`, `expiryDuration`, `milestones`, `conflictHandler` are suggested
- The caller of this endpoint can be a funder (customer) or a contractor that suggest grants to funders.
- As part of the execution, new contract id is assigned and the `Contract` info is saved on-chain.

#### CancelContract

`CancelContract` is the process of cancelling the offer sent by mistake or for being not accepted by the counter party.

- `contractId` is passed to the endpoint
- Only the sender of this contract could cancel the contract
- Contract status is modified to `CANCELLED` after the successful execution

#### AcceptContract

`AcceptContract` is the process of accepting offer by counter party of the contract.

- `contractId` is passed to the endpoint
- Contract can only be accepted when the status is `CREATED` and not `CANCELLED`, `ACCEPTED`, `PAUSED`
- Contract can only be accepted if it's under the expiry time
- Contract should be only accepted by counter party
- Contract status is set to `ACCEPTED` after the successful execution

#### PauseContract

`PauseContract` is the process of pausing the contract that is active by one of the contract participants.

- `contractId` is passed to the endpoint
- Contract status should be `ACCEPTED` to be paused
- Only one of the participant can pause (not third party)
- Contract status is set to `PAUSED` after the successful execution

#### ResumeContract

`ResumeContract` is the process of resuming paused contract by the party who paused the contract

- `contractId` is passed to the endpoint
- Check if the caller is the party paused the contract
- Check if the contract is in `PAUSED` status
- Contract status is set to `ACCEPTED` after the successful execution
- Contract `pausedBy` field is emptied.

#### PayPartialMilestone

`PayPartialMilestone` is the process of paying partial amount for the active milestone and not complete the milestone.

- `contractId` and `amount` fields are passed to the endpoint
- contract should not be at `CREATED` status (offer status), and should be one of `ACCEPTED`, `PAUSED`, or `COMPLETED`
- Ensure the milestone is funded milestone
- Ensure the total payment amount for the milestone does not exceed total funded amount
- Execute the token transfer from the realm to the contractor

#### PayAndCompleteActiveMilestone

`PayAndCompleteActiveMilestone` is the process of paying full milestone and completing the milestone, and move to next milestone.

- `contractId` field is passed to the endpoint
- contract should not be at `CREATED` status (offer status), and should be one of `ACCEPTED`, `PAUSED`, or `COMPLETED`
- Check if there's unpaid amount exist and if so, execute the remaining payment
- Move to next milestone by increasing `activeMilestone` by 1

#### FundMilestone

`FundMilestone` is an endpoint to put funds on escrow for the active milestone.

- `contractId` field is passed to the endpoint
- contract should not be at `CREATED` status (offer status), and should be one of `ACCEPTED`, `PAUSED`, or `COMPLETED`
- Ensure the caller is the funder
- Check milestone is not already funded
- Pay the amount configured on active milestone
- Transfer funds from funder to the realm
- Set `funded` flag as true

#### AddUpcomingMilestone

`AddUpcomingMilestone` is an endpoint to prepare upcoming milestone information on-chain.

- `contractId`, `title`, `amount`, `duration` fields are passed to the endpoint
- Ensure that the contract has not been completed
- Compose milestone information from passed fields
- Put the milestone at the end of existing milestones

#### CancelUpcomingMilestone

`CancelUpcomingMilestone` is an endpoint to remove upcoming milestone to be cancelled.

- `contractId` and `milestoneId` fields are passed
- Ensure the endpoint is called by one of contract participants
- Ensure the milestone is not funded
- Remove the milestone from the list

#### CompleteContract

`CompleteContract` is an endpoint to finish the contract by contract funder.

- `contractId` field is passed
- Ensure that the contract is in accepted status
- Check the caller is the funder of the contract
- Ensure tht no funded milestone exists
- Set the contract status as `COMPLETED`

#### SuggestConflictHandler

`SuggestConflictHandler` is an endpoint to suggest a conflict handler by a contract participant.

- `contractId` and `conflictHandler` fields are passed
- Ensure that the suggestor is one of the contract participants
- Ensure the conflict handler is different from already set conflict handler
- Set the `handlerCandidate` with `conflictHandler` param passed
- Set the `handlerSuggestor` with `caller`

#### ApproveConflictHandler

`ApproveConflictHandler` is an endpoint to approve a conflict handler suggested by the other party of the contract.

- `contractId` and `conflictHandler` fields are passed
- Ensure that the suggestor is one of the contract participants
- Ensure that caller is not a `handlerSuggestor`
- Ensure that `handlerCandidate` is same as `conflictHandler` approving
- Update `conflictHandler` to approved one

#### CompleteContractByConflictHandler

`CompleteContractByConflictHandler` is an endpoint to resolve conflict and complete the contract by conflict handler.

- `contractId` and `contractorAmount` fields are passed
- Ensure that contract is paused
- Ensure that the caller or `prevRealm` is the conflictHandler
- Ensure that active milestone is funded
- Calculate funder amount from `contractorAmount` field passed
- Transfer tokens to contractor and funder
- Move the milestone to next one
- Complete the contract

### GiveFeedback

`GiveFeedback` is an endpoint to give final feedback on the contract after the completion of the contract by both parties.

- `contractId` and `feedback` fields are passed
- Ensure that the contract is completed
- If the caller is a funder, update `funderFeedback` from passed `feedback` param
- If the caller is a contract, update `contractorFeedback` from passed `feedback` param

### View functions

#### CurrentRealm

`CurrentRealm` returns the address of the `escrow` realm.

#### GetContracts

`GetContracts` is an internal function to get paginated result of contracts.

#### RenderContract

`RenderContract` is a function to render a contract as human readable JSON from passed contract id.

#### RenderContracts

`RenderContracts` is a function to render paginated result of contracts as human readable JSON from passed `startAfter` and `limit`.
