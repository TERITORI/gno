package dao_proposal_single

import (
	"encoding/binary"
	"strings"

	"gno.land/p/demo/daodao/interfaces"
)

type UpdateSettingsMessage struct {
	dao_interfaces.ExecutableMessage

	Threshold *dao_interfaces.Threshold
}

func (usm *UpdateSettingsMessage) Type() string {
	return "UpdateSettings"
}

func (usm *UpdateSettingsMessage) String() string {
	ss := []string{usm.Type()}
	if usm.Threshold != nil {
		ss = append(ss, "Threshold type: ThresholdQuorum\nThreshold: "+usm.Threshold.ThresholdQuorum.Threshold.String()+"\nQuorum: "+usm.Threshold.ThresholdQuorum.Quorum.String())
	}
	return strings.Join(ss, "\n--\n")
}

func NewUpdateSettingsHandler(mod *daoProposalSingle) dao_interfaces.MessageHandler {
	return &updateSettingsHandler{mod: mod}
}

type updateSettingsHandler struct {
	dao_interfaces.MessageHandler

	mod *daoProposalSingle
}

func (h *updateSettingsHandler) Execute(message dao_interfaces.ExecutableMessage) {
	usm := message.(*UpdateSettingsMessage)

	if usm.Threshold != nil {
		h.mod.opts.Threshold = *usm.Threshold
	}
}

func (h *updateSettingsHandler) Type() string {
	return UpdateSettingsMessage{}.Type()
}
