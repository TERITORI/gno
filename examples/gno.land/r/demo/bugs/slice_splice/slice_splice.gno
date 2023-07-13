package slice_splice

import (
	"strings"
)

var slice = []string{}

func Push() {
	slice = append(slice, "1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
}

func Splice() []string {
	slice = slice[4:5]
	return slice
}

func Render(path string) string {
	return strings.Join(slice, ",")
}
