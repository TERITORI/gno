#!/bin/sh

gnokey add gopher
- addr: g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

gnokey add gopher2
- addr: g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq

TERITORI=g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5
GOPHER=g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

# check balance
gnokey query bank/balances/$TERITORI -remote="51.15.236.215:26657"

# Send 10 GNOT to realm address
gnokey maketx send  \
  -send="10000000ugnot" \
  -to="g1zeqyg0q5e7m7sr3grzhsq7qpmqymx6uqatts0u" \
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
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/registry" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_01" \
  teritori

gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/bar" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/bar_01" \
  teritori

# Register Bank token
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_01" \
  -func="RegisterBankToken" \
  -args="ugnot" \
  teritori

# Register GRC20 token while deploying
gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/bar" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/bar" \
  teritori

gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/foo" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
  teritori

# Get Faucet
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
  -func="Faucet" \
  teritori

# Transfer to realm
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
  -func="Transfer" \
  -args="g1zeqyg0q5e7m7sr3grzhsq7qpmqymx6uqatts0u" \
  -args="5000000" \
  teritori

# Deploy baz
gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/baz" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/baz" \
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
  -pkgpath="gno.land/r/x/grc20_dynamic_call/wrapper" \
  teritori

# Transfer ugnot (0.1GNOT to TERITORI)
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_01" \
  -func="TransferByInterfaceName" \
  -args="ugnot" \
  -args="$TERITORI" \
  -args="100000" \
  teritori

# Transfer foo (0.1FOO to TERITORI)
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_01" \
  -func="TransferByInterfaceName" \
  -args="foo" \
  -args="$TERITORI" \
  -args="100000" \
  teritori

# Query RealmAddr
gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_01
RealmAddr()" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_01
BalanceOfByInterfaceName(\"ugnot\",\"g1zeqyg0q5e7m7sr3grzhsq7qpmqymx6uqatts0u\")" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_01
BalanceOfByInterfaceName(\"foo\",\"g1zeqyg0q5e7m7sr3grzhsq7qpmqymx6uqatts0u\")" -remote="51.15.236.215:26657"
