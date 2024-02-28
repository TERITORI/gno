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
  -pkgdir="./examples/gno.land/p/demo/teritori/token_registry" \
  -pkgpath="gno.land/p/demo/teritori/token_registry_3" \
  teritori

# # Register Bank token
# gnokey maketx call \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_02" \
#   -func="RegisterBankToken" \
#   -args="ugnot" \
#   teritori

# # Register GRC20 token while deploying
# gnokey maketx addpkg  \
#   -deposit="1ugnot" \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/bar" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/bar" \
#   teritori

# gnokey maketx addpkg  \
#   -deposit="1ugnot" \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/foo" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
#   teritori

# # Get Faucet
# gnokey maketx call \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
#   -func="Faucet" \
#   teritori

# # Transfer to realm
# gnokey maketx call \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/foo" \
#   -func="Transfer" \
#   -args="g19ffr0zd3ad8n4tr7rxff6dte8dxxss2sleajc5" \
#   -args="5000000" \
#   teritori

# # Deploy baz
# gnokey maketx addpkg  \
#   -deposit="1ugnot" \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/baz" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/baz" \
#   teritori

# # Deploy wrapper & register to registry
# gnokey maketx addpkg  \
#   -deposit="1ugnot" \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgdir="./examples/gno.land/r/x/grc20_dynamic_call/wrapper" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/wrapper" \
#   teritori

# # Transfer ugnot (0.1GNOT to TERITORI)
# gnokey maketx call \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_02" \
#   -func="TransferByInterfaceName" \
#   -args="ugnot" \
#   -args="$TERITORI" \
#   -args="100000" \
#   teritori

# # Transfer foo (0.1FOO to TERITORI)
# gnokey maketx call \
#   -gas-fee="1ugnot" \
#   -gas-wanted="5000000" \
#   -broadcast="true" \
#   -remote="51.15.236.215:26657" \
#   -chainid="teritori-1" \
#   -pkgpath="gno.land/r/x/grc20_dynamic_call/registry_02" \
#   -func="TransferByInterfaceName" \
#   -args="foo" \
#   -args="$TERITORI" \
#   -args="100000" \
#   teritori

# # Query RealmAddr
# gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_02
# RealmAddr()" -remote="51.15.236.215:26657"

# gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_02
# BalanceOfByInterfaceName(\"ugnot\",\"g19ffr0zd3ad8n4tr7rxff6dte8dxxss2sleajc5\")" -remote="51.15.236.215:26657"

# gnokey query "vm/qeval" -data="gno.land/r/x/grc20_dynamic_call/registry_02
# BalanceOfByInterfaceName(\"foo\",\"g19ffr0zd3ad8n4tr7rxff6dte8dxxss2sleajc5\")" -remote="51.15.236.215:26657"
