package havl

import (
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
)

type Tree struct {
	root avl.Tree // height -> *avl.Tree
}

// this is not optimized at all, we make a full copy on write

func NewTree() *Tree {
	return &Tree{}
}

func (t *Tree) Size(height int64) int {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.Size()
}

func (t *Tree) Has(key string, height int64) (has bool) {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.Has(key)
}

func (t *Tree) Get(key string, height int64) (value interface{}, exists bool) {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.Get(key)
}

func (t *Tree) GetByIndex(index int, height int64) (key string, value interface{}) {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.GetByIndex(index)
}

func (t *Tree) Set(key string, value interface{}) (updated bool) {
	root := t.getOrCreateCurrentRoot()
	return root.Set(key, value)
}

func (t *Tree) Remove(key string) (value interface{}, removed bool) {
	root := t.getOrCreateCurrentRoot()
	return root.Remove(key)
}

// Shortcut for TraverseInRange.
func (t *Tree) Iterate(start, end string, height int64, cb avl.IterCbFn) bool {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.Iterate(start, end, cb)
}

// Shortcut for TraverseInRange.
func (t *Tree) ReverseIterate(start, end string, height int64, cb avl.IterCbFn) bool {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.ReverseIterate(start, end, cb)
}

// Shortcut for TraverseByOffset.
func (t *Tree) IterateByOffset(offset int, count int, height int64, cb avl.IterCbFn) bool {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.IterateByOffset(offset, count, cb)
}

// Shortcut for TraverseByOffset.
func (t *Tree) ReverseIterateByOffset(offset int, count int, height int64, cb avl.IterCbFn) bool {
	snapshot, _ := t.GetSnapshot(height)
	return snapshot.ReverseIterateByOffset(offset, count, cb)
}

func (t *Tree) GetSnapshot(height int64) (*avl.Tree, int64) {
	if height <= 0 {
		height = std.GetHeight()
	}
	var snapshot *avl.Tree
	snapshotHeight := 1
	t.root.ReverseIterate(getPaddedKey(height), "", func(key string, value interface{}) bool {
		snapshot = value.(*avl.Tree)
		var err error
		snapshotHeight, err = strconv.Atoi(key)
		if err != nil {
			panic("internal error: failed to unmarshal key")
		}
		return true
	})
	if snapshot == nil {
		snapshot = avl.NewTree()
	}
	return snapshot, int64(snapshotHeight)
}

// utils

func getPaddedKey(height int64) string {
	if height < 0 {
		panic("internal error: negative height")
	}
	val := strconv.Itoa(int(height))
	return strings.Repeat("0", len("9223372036854775807")-len(val)) + val
}

func clone(t *Tree) *Tree {
	r := Tree{}
	t.root.Iterate("", "", func(key string, value interface{}) bool {
		r.Set(key, value)
		return false
	})
	return &r
}

func (t *Tree) getOrCreateCurrentRoot() *avl.Tree {
	heightKey := getPaddedKey(std.GetHeight())
	iroot, ok := t.root.Get(heightKey)
	var root *avl.Tree
	if ok {
		root = iroot.(*avl.Tree)
	} else {
		root = avl.NewTree()
		t.root.Set(heightKey, root)
	}
	return root
}
