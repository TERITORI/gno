package tori

import (
	"encoding/binary"
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/binutils"
	"gno.land/p/demo/daodao/interfaces"
	"gno.land/r/demo/users"
)

type ExecutableMessageMintTori struct {
	dao_interfaces.ExecutableMessage

	Address users.AddressOrName
	Amount  uint64
}

func (msg *ExecutableMessageMintTori) Type() string {
	return "MintTori"
}

func (msg *ExecutableMessageMintTori) String() string {
	var ss []string
	ss = append(ss, msg.Type())
	s := "Address: " + string(msg.Address) + "\n"
	s += "Amount: " + strconv.FormatUint(msg.Amount, 10)
	ss = append(ss, s)
	return strings.Join(ss, "\n---\n")
}

func (msg *ExecutableMessageMintTori) Binary() []byte {
	b := []byte{}
	b = append(b, binutils.EncodeLengthPrefixedStringUint16BE(msg.Type())...)
	b = append(b, binutils.EncodeLengthPrefixedStringUint16BE(string(msg.Address))...)
	b = binary.BigEndian.AppendUint64(b, msg.Amount)
	return b
}

func ExecutableMessageMintToriFromBinary(b []byte) *ExecutableMessageMintTori {
	msg := &ExecutableMessageMintTori{}
	t, b := binutils.MustDecodeLengthPrefixedStringUint16BE(b)
	if t != msg.Type() {
		panic("invalid type")
	}
	var addr string
	addr, b = binutils.MustDecodeLengthPrefixedStringUint16BE(b)
	msg.Address = users.AddressOrName(addr)
	msg.Amount, b = binary.BigEndian.Uint64(b), b[8:]
	return msg
}

type MintToriHandler struct {
	dao_interfaces.MessageHandler
}

func NewMintToriHandler() *MintToriHandler {
	return &MintToriHandler{}
}

func (h *MintToriHandler) Execute(imsg dao_interfaces.ExecutableMessage) {
	msg := imsg.(*ExecutableMessageMintTori)
	Mint(msg.Address, msg.Amount)
}

func (h *MintToriHandler) Type() string {
	return ExecutableMessageMintTori{}.Type()
}

func (h *MintToriHandler) FromBinary(b []byte) dao_interfaces.ExecutableMessage {
	return ExecutableMessageMintToriFromBinary(b)
}

type ExecutableMessageBurnTori struct {
	dao_interfaces.ExecutableMessage

	Address users.AddressOrName
	Amount  uint64
}

func (msg *ExecutableMessageBurnTori) Type() string {
	return "BurnTori"
}

func (msg *ExecutableMessageBurnTori) String() string {
	var ss []string
	ss = append(ss, msg.Type())
	s := "Address: " + string(msg.Address) + "\n"
	s += "Amount: " + strconv.FormatUint(msg.Amount, 10)
	ss = append(ss, s)
	return strings.Join(ss, "\n---\n")
}

func (msg *ExecutableMessageBurnTori) Binary() []byte {
	b := []byte{}
	b = append(b, binutils.EncodeLengthPrefixedStringUint16BE(msg.Type())...)
	b = append(b, binutils.EncodeLengthPrefixedStringUint16BE(string(msg.Address))...)
	b = binary.BigEndian.AppendUint64(b, msg.Amount)
	return b
}

func ExecutableMessageBurnToriFromBinary(b []byte) *ExecutableMessageBurnTori {
	msg := &ExecutableMessageBurnTori{}
	t, b := binutils.MustDecodeLengthPrefixedStringUint16BE(b)
	if t != msg.Type() {
		panic("invalid type")
	}
	var addr string
	addr, b = binutils.MustDecodeLengthPrefixedStringUint16BE(b)
	msg.Address = users.AddressOrName(addr)
	msg.Amount, b = binary.BigEndian.Uint64(b), b[8:]
	return msg
}

type BurnToriHandler struct {
	dao_interfaces.MessageHandler
}

func NewBurnToriHandler() *BurnToriHandler {
	return &BurnToriHandler{}
}

func (h *BurnToriHandler) Execute(imsg dao_interfaces.ExecutableMessage) {
	msg := imsg.(*ExecutableMessageBurnTori)
	Burn(msg.Address, msg.Amount)
}

func (h *BurnToriHandler) Type() string {
	return ExecutableMessageBurnTori{}.Type()
}

func (h *BurnToriHandler) FromBinary(b []byte) dao_interfaces.ExecutableMessage {
	return ExecutableMessageBurnToriFromBinary(b)
}
