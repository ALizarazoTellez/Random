package main

import (
	"reflect"
	"testing"
)

func TestParseLine(t *testing.T) {
	line := `a b c`
	want := []string{"a", "b", "c"}
	if got := parseLine(line); !reflect.DeepEqual(got, want) {
		t.Log("Line:", line)
		t.Errorf("Got %q, want %q", got, want)
	}

	line = `"a house" bcde "c"`
	want = []string{"a house", "bcde", "c"}
	if got := parseLine(line); !reflect.DeepEqual(got, want) {
		t.Log("Line:", line)
		t.Errorf("Got %q, want %q", got, want)
	}

	line = `"Wake Up" Instant "Mon 12:34" "Thu 15:12"`
	want = []string{"Wake Up", "Instant", "Mon 12:34", "Thu 15:12"}
	if got := parseLine(line); !reflect.DeepEqual(got, want) {
		t.Log("Line:", line)
		t.Errorf("Got %q, want %q", got, want)
	}
}
