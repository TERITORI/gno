package slice_pop_push

import (
	"strings"
)

var slice = []string{"undead-element"}

func Pop() []string {
	slice = slice[:len(slice)-1]
	return slice
}

func Push() []string {
	slice = append(slice, "new-element")
	return slice
}

func Render(path string) string {
	return strings.Join(slice, ",")
}
