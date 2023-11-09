package conflict_handler

import (
	escrow "gno.land/r/demo/escrow_12"
)

func HandleConflict(contractId uint64, contractorAmount uint64) {
	escrow.CompleteContractByConflictHandler(contractId, contractorAmount)
}
