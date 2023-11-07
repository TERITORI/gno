# Conflict Solver Template

Conflict Solver Template is a minimum viable version of conflict solver realm that handles conflict between two parties on escrow realm.

## Conflict Solver Requirement

Conflict solver realm should import escrow realm and should have a function to call `escrow.CompleteContractByConflictHandler`.

The conflict solving logic could be implemented to solve puzzle, to bet using VRF, or implemented as a third party driven solution like Justice DAO.

## Template functionality

Conflict solver template has `HandleConflict` function that calls `escrow.CompleteContractByConflictHandler` directly and passing the received params to the escrow realm, anyone can call it.
