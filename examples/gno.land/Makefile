KEY = MyKey
BASE = teritori
REMOTE = http://127.0.0.1:26657
CHAIN_ID = dev

.PHONY: add_social_feeds_realm add_utf16_pkg add_ujson_pkg add_flags_index_pkg add_dao_interfaces_pkg add_social_feed all

add_agregator_realm:
	gnokey maketx addpkg \
		-deposit="1ugnot" \
		-gas-fee="1ugnot" \
		-gas-wanted="50000000" \
		-broadcast="true" \
		-chainid="${CHAIN_ID}" \
		-remote="${REMOTE}" \
		-pkgdir="./r/demo/teritori/worx_aggregator" \
		-pkgpath="gno.land/r/${BASE}/worx_aggregator" \
		${KEY}

add_random_worx_realm:
	gnokey maketx addpkg \
		-deposit="1ugnot" \
		-gas-fee="1ugnot" \
		-gas-wanted="50000000" \
		-broadcast="true" \
		-chainid="${CHAIN_ID}" \
		-remote="${REMOTE}" \
		-pkgdir="./r/demo/teritori/providers/random_pusher" \
		-pkgpath="gno.land/r/${BASE}/providers/random_pusher" \
		${KEY}


add_worx_pkg:
	gnokey maketx addpkg \
		-deposit="1ugnot" \
		-gas-fee="1ugnot" \
		-gas-wanted="50000000" \
		-broadcast="true" \
		-chainid="${CHAIN_ID}" \
		-remote="${REMOTE}" \
		-pkgdir="./p/demo/teritori/worx" \
		-pkgpath="gno.land/p/${BASE}/worx" \
		${KEY}


register_dataprovider:
	gnokey maketx call \
		-pkgpath "gno.land/r/${BASE}/worx_aggregator" \
		-func="RegisterDataProvider" \
		-gas-fee="1000000ugnot" \
		-gas-wanted="3000000" \
		-remote="${REMOTE}" \
		-chainid="${CHAIN_ID}" \
		-broadcast \
		-args "gno.land/r/teritori/providers/random_pusher" \
		${KEY}

push_worx:
	gnokey maketx call \
		-pkgpath "gno.land/r/${BASE}/providers/random_pusher" \
		-func="RandWorx" \
		-gas-fee="1000000ugnot" \
		-gas-wanted="3000000" \
		-remote="${REMOTE}" \
		-chainid="${CHAIN_ID}" \
		-broadcast \
		-args "g14vxq5e5pt5sev7rkz2ej438scmxtylnzv5vnkw" \
		${KEY}

all: add_utf16_pkg add_ujson_pkg add_flags_index_pkg add_dao_interfaces_pkg add_social_feeds_realm add_social_feed
