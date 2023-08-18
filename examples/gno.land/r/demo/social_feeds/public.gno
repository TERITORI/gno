package social_feeds

import (
	"encoding/base64"
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/flags_index"
	"gno.land/p/demo/ufmt"
)

// Only registered user can create a new feed
// For the flexibility when testing, allow all user to create feed
func CreateFeed(name string) FeedID {
	pkgpath := std.CurrentRealmPath()

	fid := incGetFeedID()
	caller := std.PrevRealm().Addr()
	url := strings.Replace(pkgpath, "gno.land", "", -1) + ":" + name
	feed := newFeed(fid, url, name, caller)
	fidkey := feedIDKey(fid)
	gFeeds.Set(fidkey, feed)
	gFeedsByName.Set(name, feed)
	return feed.id
}

// Anyone can create a post in a existing feed, allow un-registered users also
func CreatePost(fid FeedID, parentID PostID, catetory uint64, metadata string) PostID {
	caller := std.PrevRealm().Addr()

	feed := mustGetFeed(fid)
	post := feed.AddPost(caller, parentID, catetory, metadata)
	return post.id
}

// Only post's owner can edit post
func EditPost(fid FeedID, pid PostID, category uint64, metadata string) {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)
	post := feed.MustGetPost(pid)

	if caller != post.creator {
		panic("you are not creator of this post")
	}

	post.Update(category, metadata)
}

// Only owner can delete the post
func DeletePost(fid FeedID, pid PostID) {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)
	post := feed.MustGetPost(pid)

	if caller != post.creator {
		panic("you are not creator of this post")
	}

	post.Delete()
}

// Any one can react post
func ReactPost(fid FeedID, pid PostID, icon string, up bool) {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)
	post := feed.MustGetPost(pid)

	post.React(icon, up)
}

func TipPost(fid FeedID, pid PostID) {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)
	post := feed.MustGetPost(pid)

	post.Tip(caller, post.creator)
}

// Get a list of flagged posts
// NOTE: We can support multi feeds in the future but for now we will have only 1 feed
// Return stringified list in format: postStr-count,postStr-count
func GetFlaggedPosts(fid FeedID, offset uint64, limit uint8) string {
	feed := mustGetFeed(fid)

	// Already sorted by count descending
	flags := feed.flags.GetFlags(uint64(limit), offset)

	var postList []string
	for _, flagCount := range flags {
		flagID := flagCount.FlagID
		count := flagCount.Count

		feedID, postID := parseFlagID(flagID)
		if feedID != feed.id {
			continue
		}

		post := feed.GetPost(postID)
		postList = append(postList, ufmt.Sprintf("%s", post))
	}

	SEPARATOR := ","
	res := strings.Join(postList, SEPARATOR)
	return res
}

// NOTE: due to bug of std.PrevRealm().Addr() return "" when query so we user this proxy function temporary
// in waiting of correct behaviour of std.PrevRealm().Addr()
func GetPosts(fid FeedID, user string, categories []uint64, offset uint64, limit uint8) string {
	caller := std.PrevRealm().Addr()

	return GetPostsWithCaller(fid, caller.String(), user, categories, offset, limit)
}

func GetPostsWithCaller(fid FeedID, callerAddrStr string, user string, categories []uint64, offset uint64, limit uint8) string {
	// BUG: normally std.PrevRealm().Addr() should return a value instead of empty
	// Fix is in progress on Gno side
	feed := mustGetFeed(fid)
	caller := std.Address(callerAddrStr)

	// Return flagged posts
	if len(categories) == 1 && categories[0] == uint64(9) {
		return GetFlaggedPosts(fid, offset, limit)
	}

	var postList []string
	var skipped uint64

	// Create an avlTree for optimizing the check
	requestedCategories := avl.NewTree()
	for _, category := range categories {
		catStr := strconv.FormatUint(category, 10)
		requestedCategories.Set(catStr, true)
	}

	feed.posts.Iterate("", "", func(key string, value interface{}) bool {
		post := value.(*Post)

		postCatStr := strconv.FormatUint(post.category, 10)

		// NOTE: this search mechanism is not efficient, only for demo purpose
		if post.parentID == uint64(0) && post.deleted == false {
			if requestedCategories.Size() > 0 && !requestedCategories.Has(postCatStr) {
				return false
			}

			if user != "" && std.Address(user) != post.creator {
				return false
			}

			// Filter hidden post
			flagID := getFlagID(feed.id, post.id)
			if feed.flags.HasFlagged(flagID, callerAddrStr) {
				return false
			}

			if skipped < offset {
				skipped++
				return false
			}

			postList = append(postList, post.String())
		}

		if len(postList) == limit {
			return true
		}

		return false
	})

	SEPARATOR := ","
	res := strings.Join(postList, SEPARATOR)
	return res
}

// Get comments list
// NOTE: Does not support limit/offset for now, just return all the comments
func GetComments(fid FeedID, pid PostID) string {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)
	post := feed.MustGetPost(pid)

	var subpostList []string
	post.comments.Iterate("", "", func(key string, value interface{}) bool {
		subpost := value.(*Post)

		if subpost.parentID == pid && subpost.deleted == false {
			subpostList = append(subpostList, subpost.String())
		}

		return false
	})

	SEPARATOR := ","
	res := strings.Join(subpostList, SEPARATOR)
	return res
}

// Get Post
func GetPost(fid FeedID, pid PostID) string {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)

	data, ok := feed.posts.Get(postIDKey(pid))
	if !ok {
		panic("Unable to get post")
	}

	post := data.(*Post)
	return post.String()
}

func FlagPost(fid FeedID, pid PostID) {
	caller := std.PrevRealm().Addr()
	feed := mustGetFeed(fid)

	feed.FlagPost(caller, pid)
}

func GetFlags(fid FeedID, limit uint64, offset uint64) string {
	feed := mustGetFeed(fid)

	type FlagCount struct {
		FlagID flags_index.FlagID
		Count  uint64
	}

	flags := feed.flags.GetFlags(limit, offset)

	var res []string
	for _, flag := range flags {
		res = append(res, ufmt.Sprintf("%s:%d", flag.FlagID, flag.Count))
	}

	return strings.Join(res, "|")
}

// TODO: allow only creator to call
func GetFeedByID(fid FeedID) *Feed {
	return mustGetFeed(fid)
}

func MigrateFromPreviousFeed() {
	feed := &Feed{}

	// fid := social_feeds.FeedID(1)
	// srcFeed := social_feeds.GetFeedByID(fid)
	// feed.MigrateFrom(srcFeed.(*Feed))
}
