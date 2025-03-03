package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

type wallet struct {
	Groups []group
	Flows  []flow
}

func (w wallet) totalMoney() float64 {
	total := float64(0)
	for _, g := range w.Groups {
		total += g.totalMoney()
	}

	return total
}

func (w wallet) indexGroup(name string) int {
	for i, g := range w.Groups {
		if g.Name == name {
			return i
		}
	}

	return -1
}

type group struct {
	Name         string
	Transactions []transaction
	MaximumMoney float64
	StartDate    time.Duration
	EndDate      time.Duration
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
	for _, g := range wallet.Groups {
		fmt.Printf("\t%s: $%.2f.\n", g.Name, g.totalMoney())
	}
	fmt.Printf("Total money: $%.2f.\n", wallet.totalMoney())
}

func addIncome(wallet wallet) {
	var quantity float64
	fmt.Print("Quantity: ")
	fmt.Scanf("%f", &quantity)

	last := quantity
	for quantity != 0 {
		for _, f := range wallet.Flows {
			index := wallet.indexGroup(f.Target)
			if index < 0 {
				fmt.Println("Ignoring unknown group:", f.Target)
				continue
			}

			if f.Quantity <= 1 {
				wallet.Groups[index].Transactions = append(wallet.Groups[index].Transactions, transaction{Quantity: quantity * f.Quantity})
				quantity -= quantity * f.Quantity
				continue
			}

			q := min(quantity, f.Quantity)
			quantity -= q

			wallet.Groups[index].Transactions = append(wallet.Groups[index].Transactions, transaction{Quantity: q})
		}

		fmt.Printf("Next: $%.2f.\n", quantity)

		if last == quantity {
			fmt.Println("There is no progress...")
			break
		}
		last = quantity
	}
}

func addGroup(wallet wallet) wallet {
	var name string
	fmt.Print("Group name: ")
	fmt.Scanln(&name)

	wallet.Groups = append(wallet.Groups, group{Name: name})

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
