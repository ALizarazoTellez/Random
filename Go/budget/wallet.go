package main

import "time"

type wallet struct {
	Groups map[string]group
	Flows  []flow
}

func (w wallet) totalMoney() float64 {
	total := float64(0)
	for _, g := range w.Groups {
		total += g.totalMoney()
	}

	return total
}

type group struct {
	Transactions []transaction
	Reflow       bool
	MaximumMoney float64
}

func (g group) totalMoney() float64 {
	total := float64(0)
	for _, t := range g.Transactions {
		total += t.Quantity
	}

	return total
}

type flow struct {
	Target   string
	Quantity float64 // If its <=1 is a percentage, otherwise is a literal.
}

type transaction struct {
	Tags     []string
	Quantity float64
	Time     time.Time
}
