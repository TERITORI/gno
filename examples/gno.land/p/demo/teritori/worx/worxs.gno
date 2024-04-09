package worx

type WorxKeeper struct {
	worxs []*Worx
}

func (keeper *WorxKeeper) Store(worx *Worx) {
	keeper.worxs = append(keeper.worxs, worx)
}

func (keeper *WorxKeeper) Get() []*Worx {
	return keeper.worxs 
}