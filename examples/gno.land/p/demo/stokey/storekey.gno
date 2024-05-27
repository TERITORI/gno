package stokey

import (
	"std"
	"strings"

	"gno.land/p/demo/seqid"
)

type SubKey interface {
	KeyString() string
}

type Key []SubKey

func NewKey(subKeys ...SubKey) Key {
	return Key(subKeys)
}

func (k Key) String() string {
	b := strings.Builder{}
	for _, subKey := range k {
		b.WriteString(subKey.KeyString())
	}
	return b.String()
}

// std.Address

type addrSubKey std.Address

func Address(addr std.Address) SubKey {
	return addrSubKey(addr)
}

func (a addrSubKey) KeyString() string {
	_, b, ok := std.DecodeBech32(std.Address(a))
	if !ok {
		panic("invalid address")
	}
	return string(b[:])
}

type noAddrSubKey struct{}

func NoAddress() SubKey {
	return noAddrSubKey{}
}

func (na noAddrSubKey) KeyString() string {
	return string(make([]byte, 20))
}

type nextAddrSubKey std.Address

func NextAddress(addr std.Address) SubKey {
	return nextAddrSubKey(addr)
}

func (na nextAddrSubKey) KeyString() string {
	_, b, ok := std.DecodeBech32(std.Address(na))
	if !ok {
		panic("invalid address")
	}
	for i := len(b) - 1; i >= 0; i-- {
		if b[i] == 255 {
			if i == 0 {
				panic("overflow")
			}
			b[i] = 0
		} else {
			b[i]++
			break
		}
	}
	return string(b[:])
}

// uint64

type uint64SubKey uint64

func Uint64(u uint64) SubKey {
	return uint64SubKey(u)
}

func (u uint64SubKey) KeyString() string {
	return seqid.ID(u).String()
}

// uint32

func Uint32(u uint32) SubKey {
	return uint64SubKey(u)
}
