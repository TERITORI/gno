package social_feeds

import (
	"std"
	"strconv"
	"strings"
	"time"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/flags_index"
	"gno.land/p/demo/ufmt"
)

type FeedID uint64

func (fid FeedID) String() string {
	return strconv.Itoa(int(fid))
}

type Feed struct {
	id        FeedID
	url       string
	name      string
	creator   std.Address
	owner     std.Address
	posts     avl.Tree // pidkey -> *Post
	createdAt time.Time
	deleted   avl.Tree

	flags             *flags_index.FlagsIndex
	hiddenPostsByUser avl.Tree // std.Address => *avl.Tree (postID => bool)

	postsCtr uint64
}

func newFeed(fid FeedID, url string, name string, creator std.Address) *Feed {
	if !reName.MatchString(name) {
		panic("invalid feed name: " + name)
	}

	if gFeedsByName.Has(name) {
		panic("feed already exists: " + name)
	}

	return &Feed{
		id:        fid,
		url:       url,
		name:      name,
		creator:   creator,
		owner:     creator,
		posts:     avl.Tree{},
		createdAt: time.Now(),
		deleted:   avl.Tree{},
		flags:     flags_index.NewFlagsIndex(),
		postsCtr:  0,
	}
}

func (feed *Feed) incGetPostID() PostID {
	feed.postsCtr++
	return PostID(feed.postsCtr)
}

func (feed *Feed) GetPost(pid PostID) *Post {
	pidkey := postIDKey(pid)
	post_, exists := feed.posts.Get(pidkey)
	if !exists {
		return nil
	}
	return post_.(*Post)
}

func (feed *Feed) MustGetPost(pid PostID) *Post {
	post := feed.GetPost(pid)
	if post == nil {
		panic("post does not exist")
	}
	return post
}

func (feed *Feed) AddPost(creator std.Address, parentID PostID, category uint64, metadata string) *Post {
	pid := feed.incGetPostID()
	pidkey := postIDKey(pid)

	post := newPost(feed, pid, creator, parentID, category, metadata)
	feed.posts.Set(pidkey, post)

	if parentID != 0 {
		parent := feed.MustGetPost(parentID)
		parent.comments.Set(pidkey, post)
	}
	return post
}

func (feed *Feed) FlagPost(flagBy std.Address, pid PostID) {
	flagID := getFlagID(feed.id, pid)

	if feed.flags.HasFlagged(flagID, flagBy.String()) {
		panic("already flagged")
	}

	feed.flags.Flag(flagID, flagBy.String())
}

func (feed *Feed) HidePostForUser(caller std.Address, pid PostID) {
	userAddr := caller.String()

	value, exists := feed.hiddenPostsByUser.Get(userAddr)
	var hiddenPosts *avl.Tree
	if exists {
		hiddenPosts = value.(*avl.Tree)
	} else {
		hiddenPosts = avl.NewTree()
		feed.hiddenPostsByUser.Set(userAddr, hiddenPosts)
	}

	if hiddenPosts.Has(pid.String()) {
		panic("PostID is already hidden: " + pid.String())
	}

	hiddenPosts.Set(pid.String(), true)
}

func (feed *Feed) UnHidePostForUser(userAddress std.Address, pid PostID) {
	value, exists := feed.hiddenPostsByUser.Get(userAddress.String())
	var hiddenPosts *avl.Tree
	if exists {
		hiddenPosts = value.(*avl.Tree)
		_, removed := hiddenPosts.Remove(pid.String())
		if !removed {
			panic("Post is not hidden: " + pid.String())
		}
	} else {
		panic("User has not hidden post: " + pid.String())
	}
}

func (feed *Feed) Render() string {
	pkgpath := std.CurrentRealmPath()

	str := ""
	str += "There are " + intToString(feed.posts.Size()) + " post(s) \n\n"

	if feed.posts.Size() > 0 {
		feed.posts.Iterate("", "", func(key string, value interface{}) bool {
			if str != "" {
				str += "\n"
			}

			post := value.(*Post)
			postUrl := strings.Replace(pkgpath, "gno.land", "", -1) + ":" + feed.name + "/" + post.id.String()

			str += " * [" +
				"PostID: " + post.id.String() +
				" - " + intToString(post.reactions.Size()) + " reactions " +
				" - " + intToString(post.comments.Size()) + " comments" +
				" - " + ufmt.Sprintf("%d", post.tipAmount) + " tip amount" +
				"]" +
				"(" + postUrl + ")" +
				"\n"
			return false
		})

		str += "-------------------------\n"
		str += feed.flags.Dump()
	}

	str += "---------------------------------------\n"
	if feed.hiddenPostsByUser.Size() > 0 {
		str += "Hidden posts by users:\n\n"

		feed.hiddenPostsByUser.Iterate("", "", func(userAddr string, value interface{}) bool {
			hiddenPosts := value.(*avl.Tree)
			str += "\nUser address: " + userAddr + "\n"

			hiddenPosts.Iterate("", "", func(pid string, value interface{}) bool {
				str += "- PostID: " + pid + "\n"
				return false
			})

			return false
		})
	}

	return str
}

func (feed *Feed) MigrateFrom(srcFeed *Feed) {
	if feed.id == FeedID(0) {
		feed.id = srcFeed.id
	}
	feed.url = srcFeed.url
	feed.name = srcFeed.name
	feed.creator = srcFeed.creator
	feed.owner = srcFeed.owner
	feed.createdAt = srcFeed.createdAt

	srcFeed.posts.Iterate("", "", func(postKey string, value interface{}) bool {
		post := value.(*Post)
		targetPost := &Post{}
		targetPost.MigrateFrom(post)

		feed.posts.Set(postKey, targetPost)
		return false
	})

	gFeedsCtr += 1
	fidkey := feedIDKey(feed.id)
	gFeeds.Set(fidkey, feed)
	gFeedsByName.Set(feed.name, feed)

	feed.postsCtr = srcFeed.postsCtr
}
