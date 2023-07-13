package two_slices_one_array

import (
	"strings"
)

var (
	slice          = []string{"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
	sub1  []string = nil
	sub2  []string = nil
)

func Split() {
	sub1 = slice[0:5]
	sub2 = slice[5:]
}

func Render(path string) string {
	return "slice: " + strings.Join(slice, ",") + "\n\n" + "sub1: " + strings.Join(sub1, ",") + "\n\n" + "sub2: " + strings.Join(sub2, ",")
}
