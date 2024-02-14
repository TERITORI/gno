# Contractor
gnokey maketx call \
    -pkgpath "gno.land/r/demo/users" \
    -func "Register" \
    -gas-fee 1000000ugnot \
    -gas-wanted 2000000 \
    -send="200000000ugnot" \
    -broadcast \
    -chainid "dev" \
    -args "" \
    -args "contractor" \
    -args "contractor profile" \
    -remote "127.0.0.1:26657" \
    test1

# AcceptContractor
gnokey maketx call \
    -pkgpath "gno.land/r/demo/teritori/escrow" \
    -func "AcceptContractor" \
    -gas-fee 1000000ugnot \
    -gas-wanted 2000000 \
    -send="" \
    -broadcast \
    -chainid "dev" \
    -args 0 \
    -args "g1kcdd3n0d472g2p5l8svyg9t0wq6h5857nq992f" \
    -remote "127.0.0.1:26657" \
    test1
