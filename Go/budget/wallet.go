package main

import "time"

type wallet map[string]group

func (w wallet) totalMoney() float64 {
	total := float64(0)
	for _, g := range w {
		total += g.totalMoney()
	}

	return total
}

type group struct {
	Transactions []transaction
	Flows        map[int]flow
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
	Value        float64
	IsPercentage bool
}

type transaction struct {
	Tags     []string
	Quantity float64
	Time     time.Time
}
