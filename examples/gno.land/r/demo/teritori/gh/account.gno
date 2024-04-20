package gh

import (
	"errors"
	"std"

	"gno.land/p/demo/avl"
)

// Account represents a GitHub user account or organization.
type Account struct {
	id    string
	login string
	name  string
	kind  string
}

func (a Account) ID() string   { return a.id }
func (a Account) Name() string { return a.name }
func (a Account) Kind() string { return a.kind }
func (a Account) URL() string  { return "https://github.com/" + a.login }
func (a Account) IsUser() bool { return a.kind == UserAccount }
func (a Account) IsOrg() bool  { return a.kind == OrgAccount }

// TODO: func (a Account) RepoByID() Repo ...

func (a Account) Validate() error {
	if a.id == "" {
		return errors.New("empty id")
	}

	if a.login == "" {
		return errors.New("empty login")
	}
	if a.kind == "" || (a.kind != UserAccount && a.kind != OrgAccount) {
		return errors.New("empty kind")
	}
	if a.name == "" {
		return errors.New("empty name")
	}
	// TODO: validate
	return nil
}

func (a Account) Render() string {
	return `{ "id": "` + a.id + `", "login": "` + a.login + `", "name": "` + a.name + `", "kind": "` + a.kind + `" }`
}

func (a Account) String() string {
	// XXX: better idea?
	return a.URL()
}

const (
	UserAccount string = "user"
	OrgAccount  string = "org"
)

func AccountByID(id string) *Account {
	res, ok := accounts.Get(id)
	if !ok {
		return nil
	}

	return res.(*Account)
}
