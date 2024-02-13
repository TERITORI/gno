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
