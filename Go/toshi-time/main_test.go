package main

import (
	"reflect"
	"testing"
	"time"
)

func TestDayMoment_after(t *testing.T) {
	a := dayMoment{hour: 2, minute: 15}
	b := dayMoment{hour: 1, minute: 15}

	want := true
	if got := a.after(b); got != want {
		t.Log("Testing A after B")
		t.Log("A:", a)
		t.Log("B:", b)
		t.Errorf("Got %v, want %v", got, want)
	}

	a = dayMoment{hour: 18, minute: 19}
	b = dayMoment{hour: 20, minute: 00}

	want = false
	if got := a.after(b); got != want {
		t.Log("Testing A after B")
		t.Log("A:", a)
		t.Log("B:", b)
		t.Errorf("Got %v, want %v", got, want)
	}
}

func TestDayMoment_addDuration(t *testing.T) {
	data := dayMoment{hour: 0, minute: 0}
	duration := time.Second * 60 * 10
	want := dayMoment{hour: 0, minute: 10}

	if got := data.addDuration(duration); got != want {
		t.Log("Original:", data)
		t.Log("Duration to add:", duration)
		t.Errorf("Got %q, want %q", got, want)
	}

	data = dayMoment{hour: 5, minute: 15}
	duration = time.Second * 60 * 60
	want = dayMoment{hour: 6, minute: 15}

	if got := data.addDuration(duration); got != want {
		t.Log("Original:", data)
		t.Log("Duration to add:", duration)
		t.Errorf("Got %q, want %q", got, want)
	}
}

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
