#!/bin/sh

gnokey add gopher
- addr: g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

gnokey add gopher2
- addr: g1c5y8jpe585uezcvlmgdjmk5jt2glfw88wxa3xq

TERITORI=g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5
GOPHER=g1x2xyqca98auaw9lnat2h9ycd4lx3w0jer9vjmt

# check balance
gnokey query bank/balances/$TERITORI -remote="51.15.236.215:26657"

gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/registry" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_07" \
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
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_07" \
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
  -args="g1nmh4xp6dlyrk3p484rq9p938juzrf6cmjj4n0h" \
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

# Send 10 GNOT to realm address
gnokey maketx send  \
  -send="10000000ugnot" \
  -to="g1nmh4xp6dlyrk3p484rq9p938juzrf6cmjj4n0h" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  teritori

gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -send="10000000ugnot" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_07" \
  -func="TransferFromByInterfaceName" \
  -args="ugnot" \
  -args="$TERITORI" \
  -args="g1nmh4xp6dlyrk3p484rq9p938juzrf6cmjj4n0h" \
  -args="0" \
  teritori

# Transfer ugnot (0.1GNOT to TERITORI)
gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="51.15.236.215:26657" \
  -chainid="teritori-1" \
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_07" \
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
  -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_07" \
  -func="TransferByInterfaceName" \
  -args="foo" \
  -args="$TERITORI" \
  -args="100000" \
  teritori

# Query RealmAddr
gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_07
RealmAddr()" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_07
BalanceOfByInterfaceName(\"ugnot\",\"g1nmh4xp6dlyrk3p484rq9p938juzrf6cmjj4n0h\")" -remote="51.15.236.215:26657"

gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_07
BalanceOfByInterfaceName(\"foo\",\"g1nmh4xp6dlyrk3p484rq9p938juzrf6cmjj4n0h\")" -remote="51.15.236.215:26657"
