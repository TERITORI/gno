package sdk

import (
	"fmt"

	abci "github.com/gnolang/gno/tm2/pkg/bft/abci/types"
)

// ----------------------------------------------------------------------------
// EventLogger
// ----------------------------------------------------------------------------

// EventLogger implements a simple wrapper around a slice of Event objects that
// can be emitted from.
type EventLogger struct {
	events []Event
}

func NewEventLogger() *EventLogger {
	return &EventLogger{nil}
}

func (em *EventLogger) Events() []Event { return em.events }

// EmitEvent stores a single Event object.
func (em *EventLogger) EmitEvent(event Event) {
	em.events = append(em.events, event)
}

// EmitEvents stores a series of Event objects.
func (em *EventLogger) EmitEvents(events []Event) {
	em.events = append(em.events, events...)
}

// ----------------------------------------------------------------------------
// Event
// ----------------------------------------------------------------------------

type Event = abci.Event

func NewEvent(eventType string, pkgPath string, ident string, timestamp int64, attrs ...EventAttribute) Event {
	return AttributedEvent{
		Type:       eventType,
		PkgPath:    pkgPath,
		Identifier: ident,
		Attributes: attrs,
		Timestamp:  timestamp,
	}
}

type AttributedEvent struct {
	Type       string // type of event
	PkgPath    string // event occurred package path
	Identifier string // event occurred function identifier
	Timestamp  int64
	Attributes []EventAttribute // list of event attributes (comma separated key-value pairs)
}

func (e AttributedEvent) AssertABCIEvent() {}

func (e AttributedEvent) String() string {
	return fmt.Sprintf(
		"type: %s, pkgPath: %s, fn: %s timestamp: %d, attributes: %s",
		e.Type, e.PkgPath, e.Identifier, e.Timestamp, e.Attributes,
	)
}

type EventAttribute struct {
	Key   string
	Value string
}

func NewEventAttribute(key, value string) EventAttribute {
	return EventAttribute{
		Key:   key,
		Value: value,
	}
}

func (ea EventAttribute) String() string {
	return fmt.Sprintf("%s: %s", ea.Key, ea.Value)
}
