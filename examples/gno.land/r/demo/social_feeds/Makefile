KEY = test1
GNOKEY = gnokey maketx call \
    -pkgpath "gno.land/r/demo/social_feeds" \
    -gas-fee 1000000ugnot \
    -gas-wanted 3000000 \
    -send "" \
    -broadcast

.PHONY: create_feed
create_feed:
	${GNOKEY} \
	-func "CreateFeed" \
    -args "teritori" \
    ${KEY}

.PHONY: create_post
create_post:
	${GNOKEY} \
    -func "CreatePost" \
    -args "1" \
    -args "0" \
    -args "2" \
    -args '{"gifs": [], "files": [], "title": "", "message": "Hello world 2 !", "hashtags": [], "mentions": [], "createdAt": "2023-08-03T01:39:45.522Z", "updatedAt": "2023-08-03T01:39:45.522Z"}' \
    ${KEY}

.PHONY: tip_post
tip_post:
	${GNOKEY} \
	-send "1000000ugnot" \
	-func "TipPost" \
    -args "1" \
    -args "1" \
    ${KEY}	


.PHONY: flag_post
flag_post:
	${GNOKEY} \
	-func "FlagPost" \
    -args "1" \
    -args "1" \
    ${KEY}	

.PHONY: get_post
get_post:
	gnokey query vm/qeval --data 'gno.land/r/demo/social_feeds\nGetPosts(1, "", []uint64{}, 0, 10)'

.PHONY: init
init: create_feed create_post create_post tip_post flag_post
