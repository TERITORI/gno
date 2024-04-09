package worx

import "std"


type Worx struct {
	Hours int
	Metadata string
	Address std.Address
	Points int
    Timestamp  int64
}

func NewWorx(hours int, metadata string, addr std.Address, points int, timestamp int64) *Worx{
    return &Worx{
		Hours: hours,
        Metadata: metadata,
        Address: addr,
        Points: points,
        Timestamp: timestamp,
	}
}