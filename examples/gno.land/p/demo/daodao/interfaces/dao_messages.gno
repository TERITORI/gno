package dao_interfaces

import (
	"encoding/base64"
	"encoding/binary"
	"strings"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/ujson"
)

type MessageHandler interface {
	Execute(message ExecutableMessage)
	MessageFromJSON(ast *ujson.JSONASTNode) ExecutableMessage
	Type() string
}

type MessagesRegistry struct {
	handlers *avl.Tree
}

func NewMessagesRegistry() *MessagesRegistry {
	return &MessagesRegistry{handlers: avl.NewTree()}
}

func (r *MessagesRegistry) Register(handler MessageHandler) {
	r.handlers.Set(handler.Type(), handler)
}

func (r *MessagesRegistry) MessagesFromJSON(ast *ujson.JSONASTNode) []ExecutableMessage {
	slice := ast.ParseSlice()
	msgs := make([]ExecutableMessage, 0, len(slice))
	for _, child := range ast.ArrayChildren {
		var messageType string
		var payload *ujson.JSONASTNode
		child.ParseObject([]*ujson.ParseKV{
			{Key: "type", Value: &messageType},
			{Key: "payload", Value: &payload},
		})
		h, ok := r.handlers.Get(messageType)
		if !ok {
			panic("invalid ExecutableMessage: invalid message type")
		}
		msgs = append(msgs, h.(MessageHandler).MessageFromJSON(payload))
	}
	return msgs
}

func (r *MessagesRegistry) Execute(msg ExecutableMessage) {
	h, ok := r.handlers.Get(msg.Type())
	if !ok {
		panic("invalid ExecutableMessage: invalid message type")
	}
	return h.(MessageHandler).Execute(msg)
}

func (r *MessagesRegistry) ExecuteMessages(msgs []ExecutableMessage) {
	for _, msg := range msgs {
		r.Execute(msg)
	}
}
