package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/charmbracelet/huh"
)

func main() {
	wallet := loadWallet()

	const (
		runBalance = iota
		runIncome
		runGroup
		runFlow
		runSave
		runExit
	)

	for {
		fmt.Println()

		var option int
		huh.NewSelect[int]().
			Title("What do you want to do?").
			Options(
				huh.NewOption("View balance", runBalance),
				huh.NewOption("Add income", runIncome),
				huh.NewOption("Add group", runGroup),
				huh.NewOption("Add flow", runFlow),
				huh.NewOption("Save changes", runSave),
				huh.NewOption("Exit", runExit),
			).
			Value(&option).
			Run()

		switch option {
		case runBalance:
			printBalance(wallet)
		case runIncome:
			addIncome(wallet)
		case runGroup:
			wallet = addGroup(wallet)
		case runFlow:
			wallet = addFlow(wallet)
		case runSave:
			if err := saveWallet(wallet); err != nil {
				panic(err)
			}
		case runExit:
			return
		}
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
