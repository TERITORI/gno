gnokey maketx addpkg  \
  -deposit="1ugnot" \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="https://rpc.gno.land:443" \
  -chainid="portal-loop" \
  -pkgdir="." \
  -pkgpath="gno.land/r/mikecito/gh_test_4" \
  mykey2

gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="https://rpc.gno.land:443" \
  -chainid="portal-loop" \
  -pkgpath="gno.land/r/mikecito/gh_test_4" \
  -func="AdminSetOracleAddr" \
  -args="g1d46t4el0dduffs5j56t2razaeyvnmkxlduduuw" \
  mykey2

gnokey maketx call \
  -gas-fee="1ugnot" \
  -gas-wanted="5000000" \
  -broadcast="true" \
  -remote="https://rpc.gno.land:443" \
  -chainid="portal-loop" \
  -pkgpath="gno.land/r/mikecito/gh_test_4" \
  -func="OracleUpsertAccount" \
  -args="15034695" \
  -args="omarsy" \
  -args="6h057" \
  -args="user" \
  mykey2

gnokey query "vm/qeval" -data='gno.land/r/mikecito/gh_test_4
AccountByID("15034695")' -remote="https://rpc.gno.land:443"

gnokey query "vm/qeval" -data='gno.land/r/mikecito/gh_test_4
RenderAccount("g14mfv59k38r8k5vkevpu0lpqlqra0e9trwp3d32")' -remote="https://rpc.gno.land:443"

gnokey query "vm/qeval" -data='gno.land/r/mikecito/gh_test_4
Render()' -remote="https://rpc.gno.land:443"