package social_feeds

import (
	"strconv"
	"strings"

	"gno.land/p/demo/flags_index"
)

func getFlagID(postID PostID) flags_index.FlagID {
	return flags_index.FlagID(postID.String())
}

func parseFlagID(flagID flags_index.FlagID) (PostID, PostID) {
	postID, err := strconv.Atoi(string(flagID))
	if err != nil || postID == 0 {
		panic("invalid post ID in flag ID '" + flagID + "'")
	}
	return PostID(postID)
}
