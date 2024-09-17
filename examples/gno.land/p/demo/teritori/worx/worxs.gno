package worx

import (
	"gno.land/p/demo/avl"
	"gno.land/p/demo/ufmt"
	"time"
)

type WorxKeeper struct {
	worxs *avl.Tree
}

const dayToSeconds = 1

func NewWorxKeeper() *WorxKeeper {
	return &WorxKeeper{
		worxs: avl.NewTree(),
	}
}

func (keeper *WorxKeeper) Store(worx *Worx) {
	storekey := ufmt.Sprintf("%d", time.Now().Unix())
	worxs, ok:= keeper.worxs.Get(storekey)
	if ok {
		worxsOnDay := worxs.([]*Worx)
		worxsOnDay = append(worxsOnDay, worx)
		keeper.worxs.Set(storekey, worxsOnDay)
		return
	}

	keeper.worxs.Set(storekey, []*Worx{worx})
}

func (keeper *WorxKeeper) Get() []*Worx {
	totalWorx := make([]*Worx, 0)
	keeper.worxs.Iterate("", "", func(key string, value interface{}) bool {
		worxByDay := value.([]*Worx)
		totalWorx = append(totalWorx, worxByDay...)
		return false
	})

	return totalWorx
}

func (keeper *WorxKeeper) GetFromDate(date int64) []*Worx {
	start := ufmt.Sprintf("%d", date)
	totalWorx := make([]*Worx, 0)
	keeper.worxs.Iterate(start, "", func(key string, value interface{}) bool {
		// here we account for string comparation "95" > "105" because comparing first character 9 > 1 (Comparation of lenght)
		// and simply comparing same lenght string 25 > 12 this in order to stop tree for iterating over lower dates leaves
		if len(start) > len(key) || start > key {
			return true
		}
		worxByDay := value.([]*Worx)
		totalWorx = append(totalWorx, worxByDay...)
		return false
	})

	return totalWorx
}
