package main

type nat []int

func x() (nat, []int) {
	a := nat{1}
	b := []int{2}
	return a, b
}

func main() {
	var u1 []int
	var n2 nat
	// BlockStmt
	{
		u1, n2 = x()
		// .tmp0_1, .tmp0_2 := x()
		// u1, n2 = .tmp0_1, .tmp0_2
		println(u1)
		println(n2)
		println(u1)
		println(n2)
	}
}

// Output:
// slice[(1 int)]
// (slice[(2 int)] main.nat)
// slice[(1 int)]
// (slice[(2 int)] main.nat)
