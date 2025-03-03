package main

import (
	"encoding/json"
	"fmt"
	"os"
)

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
