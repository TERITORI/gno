package dao_realm

import (
	"testing"
)

func TestProposalsJSON(t *testing.T) {
	propsJSON := GetProposalsJSON(0)
	expected := "[]"
	if propsJSON != expected {
		t.Fatalf("Expected %s, got %s", expected, propsJSON)
	}
}
