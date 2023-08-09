package boards

import (
	"encoding/binary"
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/daodao/interfaces_v3"
	"gno.land/p/demo/jsonutil_v3"
)

// Delete post

type ExecutableMessageDeletePost struct {
	dao_interfaces.ExecutableMessage

	FeedID FeedID
	PostID PostID
	Reason string
}

func (msg *ExecutableMessageDeletePost) Type() string {
	return "gno.land/r/demo/social_feeds_v5.DeletePost"
}

func (msg *ExecutableMessageDeletePost) String() string {
	var ss []string
	ss = append(ss, msg.Type())

	feed, ok := getFeed(msg.FeedID)
	s := ""

	if ok {
		s += "Feed: " + feed.name + " (" + feed.id.String() + ")"

		post := feed.GetPost(msg.PostID)
		if post != nil {
			s += "\nPost: " + post.title + " (" + post.id.String() + ")"
		} else {
			s += "\nPost: " + msg.PostID.String() + " (not found)"
		}
	} else {
		s += "Feed: " + msg.FeedID.String() + " (not found)"
	}

	s += "\nReason: " + msg.Reason

	ss = append(ss, s)

	return strings.Join(ss, "\n---\n")
}

func (msg *ExecutableMessageDeletePost) Binary() []byte {
	b := []byte{}

	t := msg.Type()
	b = binary.BigEndian.AppendUint16(b, uint16(len(t)))
	b = append(b, []byte(t)...)

	b = binary.BigEndian.AppendUint64(b, uint64(msg.FeedID))
	b = binary.BigEndian.AppendUint64(b, uint64(msg.PostID))

	b = binary.BigEndian.AppendUint16(b, uint16(len(msg.Reason)))
	b = append(b, []byte(msg.Reason)...)

	return b
}

func ExecutableMessageDeletePostFromBinary(b []byte) *ExecutableMessageDeletePost {
	msg := &ExecutableMessageDeletePost{}

	if len(b) < 2 {
		panic("invalid length - less than 2")
	}
	tl := binary.BigEndian.Uint16(b[:2])
	b = b[2:]
	if len(b) < int(tl) {
		panic("invalid length - less than expected")
	}
	t := string(b[:tl])
	if t != msg.Type() {
		panic("invalid type")
	}
	b = b[tl:]

	if len(b) < 8 {
		panic("invalid length - less than 8")
	}
	msg.FeedID = FeedID(binary.BigEndian.Uint64(b[:8]))
	b = b[8:]

	if len(b) < 8 {
		panic("invalid length - less than 8")
	}
	msg.PostID = PostID(binary.BigEndian.Uint64(b[:8]))
	b = b[8:]

	rl := binary.BigEndian.Uint16(b[:2])
	b = b[2:]
	if len(b) < int(rl) {
		panic("invalid length - less than expected")
	}
	r := string(b[:rl])
	msg.Reason = r
	// b = b[rl:]

	return msg
}

type DeletePostHandler struct {
	dao_interfaces.MessageHandler
}

func NewDeletePostHandler() *DeletePostHandler {
	return &DeletePostHandler{}
}

func (h *DeletePostHandler) Execute(imsg dao_interfaces.ExecutableMessage) {
	msg := imsg.(*ExecutableMessageDeletePost)
	DeletePost(msg.FeedID, msg.PostID, msg.Reason)
}

func (h *DeletePostHandler) Type() string {
	return ExecutableMessageDeletePost{}.Type()
}

func (h *DeletePostHandler) FromBinary(b []byte) dao_interfaces.ExecutableMessage {
	return ExecutableMessageDeletePostFromBinary(b)
}

func (h *DeletePostHandler) FromJSON(ast *jsonutil.JSONASTNode) dao_interfaces.ExecutableMessage {
	msg := &ExecutableMessageDeletePost{}
	jsonutil.ParseObjectAST(ast, []*jsonutil.ParseKV{
		{Key: "feedID", Value: &msg.FeedID},
		{Key: "postId", Value: &msg.PostID},
		{Key: "reason", Value: &msg.Reason},
	})
	return msg
}
