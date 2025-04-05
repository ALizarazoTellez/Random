// This generates a CSV containing the multiplication tables. Useful for Anki.
package main

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

const (
	minTable      = 0
	maxTable      = 12
	verticalTable = highestResult
	highestResult = maxTable * maxTable
)

var skipTables = []int{
	0, 1, 10, 100, 1000,
}

var tricks = [max(100, maxTable, verticalTable) + 1]string{
	0:   "It’s zero :)",
	1:   "It's the same.",
	2:   "Just double the number.",
	3:   "Double the number and add it to itself.",
	4:   "Double the number twice.",
	5:   "Multiply by ten, then divide by two.",
	6:   "Multiply by 3, then double the result.",
	7:   "Multiply by eight, then subtract itself.",
	8:   "Double the number three times.",
	9:   "Multiply by ten, then subtract itself.",
	10:  "Add a zero to the right.",
	11:  "Separate the number and put the sum of its extremes in the middle.",
	12:  "Multiply by ten, then add twice the original number.",
	15:  "Multiply the number by ten, then add half of itself to your multiplication.",
	16:  "Double the number four times.",
	20:  "Multiply by 10, then double that multiplication.",
	50:  "Multiply by one hundred, then divide by two.",
	25:  "Multiply by 100, then divide by 2 twice.",
	125: "Multiply by a thousand, then divide by 2 three times.",
}

func main() {
	tables := [][]string{{"A", "B", "Result", "TrickA", "TrickB"}}

	var coverage int
	var skipped int
	for a := minTable; a <= maxTable; a++ {
		if skipNumber(a) {
			skipped++
			continue
		}

		for b := minTable; b <= verticalTable; b++ {
			if skipNumber(b) || isInTable(tables, a, b) || a*b > highestResult {
				skipped++
				continue
			}

			if tricks[a] != "" || tricks[b] != "" {
				coverage++
			}

			tables = append(tables,
				[]string{strconv.Itoa(a), strconv.Itoa(b), strconv.Itoa(a * b), tricks[a], tricks[b]})
		}
	}

	fmt.Printf("Total tables: %d.\n", len(tables)-1)
	fmt.Printf("Skipped: %d.\n", skipped)
	fmt.Printf("Trick coverage: %.2f%% (%d/%d).\n", float64(coverage)/float64(len(tables)-1)*100, coverage, len(tables)-1)

	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	if err := w.WriteAll(tables); err != nil {
		panic(err)
	}

	if err := os.WriteFile("number-tables.csv", buf.Bytes(), 0666); err != nil {
		panic(err)
	}
}

func isInTable(table [][]string, a, b int) bool {
	for _, items := range table {
		a := strconv.Itoa(a)
		b := strconv.Itoa(b)

		if (items[0] == a && items[1] == b) || (items[0] == b && items[1] == a) {
			return true
		}
	}

	return false
}

func skipNumber(n int) bool {
	for _, table := range skipTables {
		if n == table {
			return true
		}
	}

	return false
}
