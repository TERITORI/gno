#!/bin/sh

gnokey add gopher
- addr: g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

gnokey add gopher2
- addr: g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq

TERITORI=g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5
GOPHER=g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

# check balance
gnokey query bank/balances/$GOPHER -remote="51.15.236.215:26657"
gnokey query bank/balances/$TERITORI -remote="51.15.236.215:26657"
gnokey query bank/balances/g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq -remote="51.15.236.215:26657"

# Send balance to gopher2 account
gnokey maketx send  \
  -send="100000000ugnot" \
  -to="g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  teritori

gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./escrow" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  teritori

# Create Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CreateContract" \
  -args="g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq" \
  -args="$TERITORI" \
  -args="ugnot" \
  -args="{}" \
  -args="60" \
  -args="Milestone1,Milestone2" \
  -args="Milestone Desc1,Milestone Desc2" \
  -args="10,15" \
  -args="86400,86400" \
  -args="https://ref.com/m1,https://ref.com/m2" \
  -args="MS_PRIORITY_HIGH,MS_PRIORITY_HIGH" \
  -args="" \
  teritori

# Cancel Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CancelContract" \
  -args="0" \
  teritori

# Accept Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="AcceptContract" \
  -args="3" \
  gopher2

gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="FundMilestone" \
  -args="0" \
  teritori

# Pause Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="PauseContract" \
  -args="0" \
  teritori

# Complete Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CompleteContract" \
  -args="0" \
  teritori

# Resume Contract
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="ResumeContract" \
  -args="1" \
  teritori

# Submit milestone as ready for review
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="ChangeMilestoneStatus" \
  -args="3" \
  -args="1" \
  -args="3" \
  gopher2

# Pay and complete milestone
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CompleteMilestoneAndPay" \
  -args="3" \
  -args="1" \
  teritori

# Fund active milestone - Start milestone
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="FundMilestone" \
  -args="0" \
  -args="2" \
  teritori

# Add upcoming milestone
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="AddUpcomingMilestone" \
  -args="0" \
  -args="Milestone3" \
  -args="Milestone3 Desc" \
  -args="20" \
  -args="86400" \
  -args="https://ref.com/m3" \
  teritori

# Cancel Upcoming Milestone
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CancelUpcomingMilestone" \
  -args="0" \
  -args="3" \
  teritori

# Suggest conflict handler
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="SuggestConflictHandler" \
  -args="0" \
  -args="gno.land/r/demo/conflict_solver_01" \
  teritori

# Approve conflict handler
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="ApproveConflictHandler" \
  -args="0" \
  -args="gno.land/r/demo/conflict_solver_01" \
  gopher2

# Complete Contract by ConflictSolver
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="CompleteContractByConflictHandler" \
  -args="0" \
  -args="50" \
  teritori

# Give feedback
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="GiveFeedback" \
  -args="0" \
  -args="Amazing work" \
  teritori

# Register token
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/escrow_17" \
  -func="RegisterBankToken" \
  -args="ugnot" \
  teritori

# Deploy wrapper & register to registry
gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/wrapper" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/wrapper_02" \
  teritori

# Query Contracts
gnokey query "vm/qeval" -data="gno.land/r/demo/escrow_17
RenderContracts(0, 10, \"ALL\", \"ALL\")" -remote="51.15.236.215:26657"

# Query contract
gnokey query "vm/qeval" -data="gno.land/r/demo/escrow_17
RenderContract(0)" -remote="51.15.236.215:26657"

# Query config
gnokey query "vm/qeval" -data="gno.land/r/demo/escrow_17
RenderConfig()" -remote="51.15.236.215:26657"

# Query escrow address
gnokey query "vm/qeval" -data="gno.land/r/demo/escrow_17
CurrentRealm()" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/demo/escrow_17
RealmAddr()" -remote="51.15.236.215:26657"

# Get gopher20 faucet
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/gopher20" \
  -func="Faucet" \
  teritori

# Approve tokens
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/demo/gopher20" \
  -func="Approve" \
  -args="g1f7p4tuu044w2qsa9m3h64ql4lrqmmjzm2f6jws" \
  -args="1000" \
  teritori

# Query balance
gnokey query "vm/qeval" -data="gno.land/r/demo/gopher20
BalanceOf(\"$TERITORI\")" -remote="51.15.236.215:26657" 

gnokey query "vm/qeval" -data="gno.land/r/demo/gopher20
Render(\"balance/g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq\")" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_08
BalanceOfByInterfaceName(\"ugnot\",\"g1ekzpjudtttrwve88dlqa4qy6wgunhv0r64skly\")" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_08
BalanceOfByInterfaceName(\"foo\",\"g1ekzpjudtttrwve88dlqa4qy6wgunhv0r64skly\")" -remote="51.15.236.215:26657"
