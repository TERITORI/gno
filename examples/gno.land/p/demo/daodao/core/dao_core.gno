package core

import (
	"std"
	"strings"
	"time"

	dao_interfaces "gno.land/p/demo/daodao/interfaces"
	"gno.land/p/demo/markdown_utils"
)

// TODO: add wrapper message handler to handle multiple proposal modules messages

type IDAOCore interface {
	AddProposalModule(proposalMod dao_interfaces.IProposalModule)
	RegisterMessageHandler(msg dao_interfaces.MessageHandler)
	ExecuteMessages(msgs []dao_interfaces.ExecutableMessage)

	GetRegistry() *dao_interfaces.MessagesRegistry // remove this??
	VotingModule() dao_interfaces.IVotingModule
	ProposalModules() []dao_interfaces.IProposalModule

	Render(path string) string
}

type daoCore struct {
	IDAOCore

	votingModule              dao_interfaces.IVotingModule
	proposalModules           []dao_interfaces.IProposalModule
	activeProposalModuleCount int
	pause                     Expiration
	realm                     std.Realm
	admin                     std.Address
	registry                  *dao_interfaces.MessagesRegistry
}

func NewDAOCore(
	votingModule dao_interfaces.IVotingModule,
	proposalModules []dao_interfaces.IProposalModule,
	messageHandlers []dao_interfaces.MessageHandler,
) IDAOCore {
	if votingModule == nil {
		panic("No vote module")
	}

	/* we don't do this check since we can't pass the core to the proposal modules before it's created
	if len(proposalModules) == 0 {
		panic("No active proposal modules")
	}
	*/

	// items will be done with profile realm

	// this registry is specific to gno since we can't do dynamic calls
	registry := dao_interfaces.NewMessagesRegistry()
	for _, handler := range messageHandlers {
		registry.Register(handler)
	}

	return &daoCore{
		realm:                     std.CurrentRealm(),
		votingModule:              votingModule,
		proposalModules:           proposalModules,
		activeProposalModuleCount: len(proposalModules),
		registry:                  registry,
	}
}

// mutations

// TODO: ExecutableMessagePause
func (d *daoCore) Pause(pauseDuration Duration) {
	d.pause = pauseDuration.AfterCurrentBlock()
}

func (d *daoCore) ExecuteAdminMsgs(msgs []dao_interfaces.ExecutableMessage) {
	caller := std.PrevRealm().Addr()
	if caller != d.admin {
		panic("Only admin can execute admin messages")
	}

	for _, msg := range msgs {
		d.registry.Execute(msg)
	}
}

func (d *daoCore) ExecuteMessages(msgs []dao_interfaces.ExecutableMessage) {
	if d.pause != nil && !d.pause.IsExpired() {
		panic("DAO is paused")
	}

	for _, msg := range msgs {
		d.registry.Execute(msg)
	}
}

// TODO: ExecutableMessageRegisterMessageHandler
func (d *daoCore) RegisterMessageHandler(msg dao_interfaces.MessageHandler) {
	d.registry.Register(msg)
}

// queries

func (d *daoCore) VotingModule() dao_interfaces.IVotingModule {
	return d.votingModule
}

func (d *daoCore) ProposalModules() []dao_interfaces.IProposalModule {
	return d.proposalModules
}

func (d *daoCore) AddProposalModule(proposalMod dao_interfaces.IProposalModule) {
	d.proposalModules = append(d.proposalModules, proposalMod)
}

func (d *daoCore) ActiveProposalModuleCount() int {
	return d.activeProposalModuleCount
}

func (d *daoCore) Render(path string) string {
	s := "# DAO Core\n"
	s += "This is a port of [DA0-DA0 contracts](https://github.com/DA0-DA0/dao-contracts)\n"
	s += markdown_utils.Indent(d.votingModule.Render(path)) + "\n"
	for _, propMod := range d.proposalModules {
		s += markdown_utils.Indent(propMod.Render(path)) + "\n"
	}
	return s
}

func (d *daoCore) GetRegistry() *dao_interfaces.MessagesRegistry {
	return d.registry
}

func GetProposalModule(core IDAOCore, moduleIndex int) dao_interfaces.IProposalModule {
	if moduleIndex < 0 {
		panic("Module index must be >= 0")
	}
	mods := core.ProposalModules()
	if moduleIndex >= len(mods) {
		panic("invalid module index")
	}
	return mods[moduleIndex]
}
