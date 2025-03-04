package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/huh"
)

const maximumPriority = 100

func printBalance(wallet wallet) {
	fmt.Printf("Total money: $%.0f.\n", wallet.totalMoney())
	for name, group := range wallet {
		if group.MaximumMoney == 0 {
			fmt.Printf("\t- %s: $%.0f.\n", name, group.totalMoney())
		} else {
			fmt.Printf("\t- %s (max: $%.0f): $%.0f.\n", name, group.MaximumMoney, group.totalMoney())
		}
	}
}

func addIncome(w wallet) {
	var quantity float64
	huh.NewInput().
		Title("What's the quantity?").
		Prompt("$").
		Validate(func(s string) error {
			var err error
			quantity, err = strconv.ParseFloat(s, 64)

			if quantity <= 0 || err != nil {
				return fmt.Errorf("you need to introduce a positive number different from zero")
			}

			return nil
		}).
		Run()

	last := quantity
	modifiedGroups := map[string]bool{}

	for quantity != 0 {
		for priority := range maximumPriority {
			for groupName, group := range w {
				if modifiedGroups[groupName] && !group.Reflow {
					continue
				}

				f, ok := group.Flows[priority]
				if !ok {
					continue
				}

				var q float64
				if f.IsPercentage {
					q = quantity * f.Value
				} else {
					q = min(f.Value, quantity)
				}

				if group.MaximumMoney != 0 {
					q = min(q, group.MaximumMoney-group.totalMoney())
				}

				if q == 0 {
					continue
				}

				if !modifiedGroups[groupName] {
					group.Transactions = append(group.Transactions, transaction{
						Quantity: q,
						Time:     time.Now(),
					})
					modifiedGroups[groupName] = true
				} else {
					group.Transactions[len(group.Transactions)-1].Quantity += q
				}

				quantity -= q
				w[groupName] = group
			}
		}

		if last == quantity {
			panic("There is no progress...")
		}
		last = quantity
	}
}

func addGroup(wallet wallet) wallet {
	var name string
	huh.NewInput().
		Title("What's the name of the new group?").
		Prompt("Name: ").
		Validate(func(s string) error {
			if strings.TrimSpace(s) == "" {
				return fmt.Errorf("empty names are not valid")
			}

			return nil
		}).
		Value(&name).
		Run()

	var hasLimit bool
	huh.NewConfirm().
		Title("Has a money limit?").
		Affirmative("Yes").
		Negative("No").
		Value(&hasLimit).
		Run()

	var maximumMoney float64
	if hasLimit {
		huh.NewInput().
			Title("What's the limit?").
			Prompt("$").
			Validate(func(s string) error {
				var err error
				maximumMoney, err = strconv.ParseFloat(s, 64)

				if maximumMoney <= 0 || err != nil {
					return fmt.Errorf("you need to introduce a positive number different from zero")
				}

				return nil
			}).
			Run()
	}

	var reflow bool
	huh.NewConfirm().
		Title("Can reflow?").
		Affirmative("Yes").
		Negative("No").
		Value(&reflow).
		Run()

	wallet[name] = group{Reflow: reflow, MaximumMoney: maximumMoney}

	return wallet
}

func addFlow(wallet wallet) wallet {
	var target string
	huh.NewSelect[string]().
		Title("What's the target group?").
		OptionsFunc(func() []huh.Option[string] {
			var groups []string
			for groupName := range wallet {
				groups = append(groups, groupName)
			}

			return huh.NewOptions(groups...)
		}, nil).
		Value(&target).
		Run()

	var priority int
	huh.NewInput().
		Title("What's the priority?").
		Prompt("? ").
		Validate(func(s string) error {
			var err error
			priority, err = strconv.Atoi(s)

			if priority < 0 || err != nil {
				return fmt.Errorf("you must introduce a positive number")
			}

			if priority > maximumPriority {
				return fmt.Errorf("the maximum priority is %d", maximumPriority)
			}

			return nil
		}).
		Run()

	var isPercentage bool
	huh.NewConfirm().
		Title("Use percentages?").
		Affirmative("Yes").
		Negative("No").
		Value(&isPercentage).
		Run()

	var value float64
	huh.NewInput().
		TitleFunc(func() string {
			if isPercentage {
				return "What's the percentage?"
			}
			return "What's the quantity?"
		}, isPercentage).
		Prompt("> ").
		Validate(func(s string) error {
			var err error
			value, err = strconv.ParseFloat(s, 64)

			if value <= 0 || err != nil {
				return fmt.Errorf("you need to introduce a positive number different of zero")
			}

			if isPercentage && value > 100 {
				return fmt.Errorf("percentages can only go up to 100%%")
			}

			if !isPercentage && value <= 1 {
				return fmt.Errorf("the quantity must be greater than 1")
			}

			if isPercentage {
				value /= 100
			}

			return nil
		}).
		Run()

	group := wallet[target]
	if group.Flows == nil {
		group.Flows = map[int]flow{}
	}
	group.Flows[priority] = flow{Value: value, IsPercentage: isPercentage}
	wallet[target] = group

	return wallet
}
