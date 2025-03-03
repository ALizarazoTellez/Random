package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"time"
)

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

func main() {
	wallet := loadWallet()

outerloop:
	for {
		fmt.Println("What do you want to do?:")
		fmt.Println("[0] Balance")
		fmt.Println("[1] Add income")
		fmt.Println("[2] Add group")
		fmt.Println("[3] Add flow")
		fmt.Println("[-1] Save & exit")

		var option int
		fmt.Scanf("%d", &option)

		switch option {
		case 0:
			printBalance(wallet)
		case 1:
			addIncome(wallet)
		case 2:
			wallet = addGroup(wallet)
		case 3:
			wallet = addFlow(wallet)
		case -1:
			break outerloop
		}
	}

	if err := saveWallet(wallet); err != nil {
		panic(err)
	}
}

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

func loadWallet() wallet {
	data, err := os.ReadFile("./wallet.json")
	if err != nil {
		println("There is not saved wallet.")
		return wallet{}
	}

	var w wallet
	if err := json.Unmarshal(data, &w); err != nil {
		println("The saved wallet is invalid.")
		return wallet{}
	}

	return w
}

func saveWallet(w wallet) error {
	data, err := json.MarshalIndent(w, "", "  ")
	if err != nil {
		return err
	}

	if err := os.WriteFile("./wallet.json", data, 0o644); err != nil {
		return err
	}

	return nil
}
