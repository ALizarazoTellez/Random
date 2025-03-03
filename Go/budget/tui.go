package main

import (
	"fmt"
	"math"
	"time"
)

func printBalance(wallet wallet) {
	for name, group := range wallet.Groups {
		fmt.Printf("\t%s: $%.2f.\n", name, group.totalMoney())
	}
	fmt.Printf("Total money: $%.2f.\n", wallet.totalMoney())
}

func addIncome(wallet wallet) {
	var quantity float64
	fmt.Print("Quantity: ")
	fmt.Scanf("%f", &quantity)

	fmt.Println("The value to add is:", quantity)

	last := quantity
	isModified := map[string]bool{}
	for quantity != 0 {
		for _, f := range wallet.Flows {
			group, ok := wallet.Groups[f.Target]
			if !ok {
				fmt.Println("Ignoring unknown group:", f.Target)
			}

			fmt.Println("Processing:", f.Target)

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
			fmt.Printf("Next: $%.2f.\n", quantity)
		}

		if last == quantity {
			fmt.Println("There is no progress...")
			break
		}
		if math.IsNaN(quantity) {
			panic("NaN detected!")
		}
		last = quantity
	}
}

func addGroup(wallet wallet) wallet {
	var name string
	fmt.Print("Group name: ")
	fmt.Scanln(&name)

	var maximumMoney float64
	fmt.Print("Maximum money (0 means no limit): ")
	fmt.Scanf("%f", &maximumMoney)

	if wallet.Groups == nil {
		wallet.Groups = make(map[string]group)
	}
	wallet.Groups[name] = group{MaximumMoney: maximumMoney}

	return wallet
}

func addFlow(wallet wallet) wallet {
	var target string
	fmt.Print("Target group: ")
	fmt.Scanln(&target)

	var quantity float64
	fmt.Print("Quantity (<= 1 uses percentage): ")
	fmt.Scanf("%f", &quantity)

	wallet.Flows = append(wallet.Flows, flow{Target: target, Quantity: quantity})

	return wallet
}
