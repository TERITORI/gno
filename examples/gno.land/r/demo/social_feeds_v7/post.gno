package social_feeds

import (
	"encoding/base64"
	"encoding/binary"
	"std"
	"strconv"
	"strings"
	"time"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/binutils"
	"gno.land/p/demo/ufmt"
	"gno.land/p/demo/ujson"
)

type PostID uint64

func (pid PostID) String() string {
	return strconv.Itoa(int(pid))
}

type Reaction struct {
	icon  string
	count uint64
}

var Categories []string = []string{
	"Reaction",
	"Comment",
	"Normal",
	"Article",
	"Picture",
	"Audio",
	"Video",
}

type Post struct {
	id        PostID
	parentID  PostID
	feedID    FeedID
	category  uint64
	metadata  string
	reactions avl.Tree // icon -> count
	comments  avl.Tree // Post.id -> *Post
	creator   std.Address
	tipAmount uint64
	deleted   bool

	createdAt time.Time
	updatedAt time.Time
	deletedAt time.Time
}

func newPost(feed *Feed, id PostID, creator std.Address, parentID PostID, category uint64, metadata string) *Post {
	return &Post{
		id:        id,
		parentID:  parentID,
		feedID:    feed.id,
		category:  category,
		metadata:  metadata,
		reactions: avl.Tree{},
		creator:   creator,
		createdAt: time.Now(),
	}
}

func (post *Post) Bytes() []byte {
	b := []byte{}
	b = binary.BigEndian.AppendUint64(b, uint64(post.id))
	b = binary.BigEndian.AppendUint64(b, uint64(post.parentID))
	b = binary.BigEndian.AppendUint64(b, uint64(post.feedID))
	b = binary.BigEndian.AppendUint64(b, post.category)
	b = append(b, EncodeLengthPrefixedStringUint32BE(post.metadata)...)
	b = append(b, binutils.EncodeLengthPrefixedStringUint16BE(post.creator.String())...)
	b = binary.BigEndian.AppendUint32(b, uint32(post.createdAt.Unix()))

	// Encode reactions
	var reactionsArr []string
	post.reactions.Iterate("", "", func(key string, value interface{}) bool {
		icon := key
		count := value.(int)

		reactionsArr = append(reactionsArr, ufmt.Sprintf("%s:%d", icon, count))
		return false
	})

	SEPARATOR := ","
	reactionsStr := strings.Join(reactionsArr, SEPARATOR)
	b = append(b, EncodeLengthPrefixedStringUint32BE(reactionsStr)...)

	// Add tipAmount
	b = binary.BigEndian.AppendUint64(b, post.tipAmount)

	return b
}

func (post *Post) String() string {
	return bytesToString(post.Bytes())
}

func (post *Post) Update(category uint64, metadata string) {
	post.category = category
	post.metadata = metadata
	post.updatedAt = time.Now()
}

func (post *Post) Delete() {
	post.deleted = true
	post.deletedAt = time.Now()
}

func (post *Post) Tip(from std.Address, to std.Address) {
	receivedCoins := std.GetOrigSend()
	amount := receivedCoins[0].Amount

	banker := std.GetBanker(std.BankerTypeOrigSend)
	// banker := std.GetBanker(std.BankerTypeRealmSend)
	coinsToSend := std.Coins{std.Coin{Denom: "ugnot", Amount: amount}}
	pkgaddr := std.GetOrigPkgAddr()

	banker.SendCoins(pkgaddr, to, coinsToSend)

	// Update tip amount
	post.tipAmount += uint64(amount)
}

// Always remove reaction if count = 0
func (post *Post) React(icon string, up bool) {
	count_, ok := post.reactions.Get(icon)
	count := 0

	if ok {
		count = count_.(int)
	}

	if up {
		count++
	} else {
		count--
	}

	if count <= 0 {
		post.reactions.Remove(icon)
	} else {
		post.reactions.Set(icon, count)
	}
}

func (post *Post) Render() string {
	return post.metadata
}

func (post *Post) FromJSON(jsonData string) {
	ast := ujson.TokenizeAndParse(jsonData)
	ast.ParseObject([]*ujson.ParseKV{
		{Key: "id", Value: &post.id},
		{Key: "parentID", Value: &post.parentID},
		{Key: "feedID", Value: &post.feedID},
		{Key: "category", Value: &post.category},
		{Key: "metadata", Value: &post.metadata},
		{Key: "reactions", CustomParser: func(node *ujson.JSONASTNode) {
			reactions := avl.NewTree()
			for _, child := range node.ObjectChildren {
				reactionCount := child.Value
				reactions.Set(child.Key, reactionCount)
			}
			post.reactions = *reactions
		}},
		{Key: "creator", Value: &post.creator},
		{Key: "tipAmount", Value: &post.tipAmount},
		{Key: "deleted", Value: &post.deleted},
		{Key: "createdAt", Value: &post.createdAt},
		{Key: "updatedAt", Value: &post.updatedAt},
		{Key: "deletedAt", Value: &post.deletedAt},
	})
}

func (post *Post) ToJSON() string {
	reactionsKV := []ujson.FormatKV{}
	post.reactions.Iterate("", "", func(key string, value interface{}) bool {
		count := value.(int)
		data := ujson.FormatKV{Key: key, Value: count}
		reactionsKV = append(reactionsKV, data)
		return false
	})
	reactions := ujson.FormatObject(reactionsKV)

	postJSON := ujson.FormatObject([]ujson.FormatKV{
		{Key: "id", Value: post.id},
		{Key: "parentID", Value: post.parentID},
		{Key: "feedID", Value: post.feedID},
		{Key: "category", Value: post.category},
		{Key: "metadata", Value: post.metadata},
		{Key: "reactions", Value: reactions, Raw: true},
		{Key: "creator", Value: post.creator},
		{Key: "tipAmount", Value: post.tipAmount},
		{Key: "deleted", Value: post.deleted},
		{Key: "createdAt", Value: post.createdAt},
		{Key: "updatedAt", Value: post.updatedAt},
		{Key: "deletedAt", Value: post.deletedAt},
	})
	return postJSON
}
