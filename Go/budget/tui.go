package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/huh"
)

func printBalance(wallet wallet) {
	fmt.Printf("Total money: $%.0f.\n", wallet.totalMoney())
	for name, group := range wallet.Groups {
		if group.MaximumMoney == 0 {
			fmt.Printf("\t- %s: $%.0f.\n", name, group.totalMoney())
		} else {
			fmt.Printf("\t- %s (max: $%.0f): $%.0f.\n", name, group.MaximumMoney, group.totalMoney())
		}
	}
}

func addIncome(wallet wallet) {
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
	isModified := map[string]bool{}
	for quantity != 0 {
		for _, f := range wallet.Flows {
			group, ok := wallet.Groups[f.Target]
			if !ok {
				panic(fmt.Sprintln("Ignoring unknown group:", f.Target))
			}

			if f.Quantity <= 1 {
				q := quantity * f.Quantity
				if group.MaximumMoney != 0 {
					q = min(q, group.MaximumMoney-group.totalMoney())
				}
				if q == 0 {
					continue
				}
				if !isModified[f.Target] {
					group.Transactions = append(group.Transactions, transaction{
						Quantity: q,
						Time:     time.Now(),
					})
					isModified[f.Target] = true
				} else {
					group.Transactions[len(group.Transactions)-1].Quantity += q
				}

				quantity -= q
			} else {
				q := min(f.Quantity, quantity)
				if group.MaximumMoney != 0 {
					q = min(q, group.MaximumMoney-group.totalMoney())
				}
				if q == 0 {
					continue
				}

				if !isModified[f.Target] {
					group.Transactions = append(group.Transactions, transaction{
						Quantity: q,
						Time:     time.Now(),
					})
					isModified[f.Target] = true
				} else {
					group.Transactions[len(group.Transactions)-1].Quantity += q
				}
				quantity -= q
			}

			wallet.Groups[f.Target] = group
		}

		if last == quantity {
			panic("There is no progress...")
			break
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

	if wallet.Groups == nil {
		wallet.Groups = make(map[string]group)
	}
	wallet.Groups[name] = group{MaximumMoney: maximumMoney}

	return wallet
}

func addFlow(wallet wallet) wallet {
	var target string
	huh.NewSelect[string]().
		Title("What's the target group?").
		OptionsFunc(func() []huh.Option[string] {
			var groups []string
			for name := range wallet.Groups {
				groups = append(groups, name)
			}

			return huh.NewOptions(groups...)
		}, nil).
		Value(&target).
		Run()

	var usesPercentage bool
	huh.NewConfirm().
		Title("Use percentages?").
		Affirmative("Yes").
		Negative("No").
		Value(&usesPercentage).
		Run()

	var quantity float64
	huh.NewInput().
		TitleFunc(func() string {
			if usesPercentage {
				return "What's the percentage?"
			}
			return "What's the quantity?"
		}, usesPercentage).
		Prompt("> ").
		Validate(func(s string) error {
			var err error
			quantity, err = strconv.ParseFloat(s, 64)

			if quantity <= 0 || err != nil {
				return fmt.Errorf("you need to introduce a positive number different of zero")
			}

			if usesPercentage && quantity > 100 {
				return fmt.Errorf("percentages can only go up to 100%%")
			}

			if !usesPercentage && quantity <= 1 {
				return fmt.Errorf("the quantity must be greater than 1")
			}

			if usesPercentage {
				quantity /= 100
			}

			return nil
		}).
		Run()

	wallet.Flows = append(wallet.Flows, flow{Target: target, Quantity: quantity})

	return wallet
}
