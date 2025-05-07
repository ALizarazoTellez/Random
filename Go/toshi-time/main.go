package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"
	"unicode"
)

type task struct {
	title    string
	duration time.Duration
	dates    []time.Time
}

func loadTasks(r io.Reader) ([]task, error) {
	data, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}

	lines := strings.Split(string(data), "\n")

	tasks := make([]task, 0)

	for _, line := range lines {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "#") {
			continue
		}

		if line == "" {
			continue
		}

		fields := parseLine(line)
		if len(fields) < 3 {
			fmt.Printf("Wrong line: %q\n", line)
			return nil, fmt.Errorf("the line needs at least 3 items")
		}

		duration, err := time.ParseDuration(fields[1])
		if err != nil {
			if fields[1] == "Instant" {
				duration = 0
			} else {
				return nil, fmt.Errorf("invalid duration %q", fields[1])
			}
		}
		times := make([]time.Time, 0, len(fields[2:]))
		for _, rawTime := range fields[2:] {
			if rawTime[0] == '*' {
				t, err := time.Parse("* 15:04", rawTime)
				if err != nil {
					return nil, err
				}

				for i := 2; i <= 8; i++ {
					times = append(times, t.AddDate(0, 0, i))
				}

				continue
			}

			t, err := time.Parse("Mon 15:04", rawTime)
			if err != nil {
				return nil, err
			}
			switch rawTime[0:3] {
			case "Mon":
				t = t.AddDate(0, 0, 2)
			case "Tue":
				t = t.AddDate(0, 0, 3)
			case "Wed":
				t = t.AddDate(0, 0, 4)
			case "Thu":
				t = t.AddDate(0, 0, 5)
			case "Fri":
				t = t.AddDate(0, 0, 6)
			case "Sat":
				t = t.AddDate(0, 0, 7)
			case "Sun":
				t = t.AddDate(0, 0, 8)
			default:
				panic("unknown " + rawTime[0:3])
			}

			times = append(times, t)
		}
		tasks = append(tasks, task{title: fields[0], duration: duration, dates: times})
	}

	return tasks, nil
}

func parseLine(line string) []string {
	fields := make([]string, 0, 3)

	for i := 0; i < len(line); i++ {
		if line[i] == '"' {
			end := i + 1
			for line[end] != '"' {
				end++
			}
			fields = append(fields, line[i+1:end])
			i = end + 1
			continue
		}

		if !unicode.IsSpace(rune(line[i])) {
			end := i + 1
			for end < len(line) && !unicode.IsSpace(rune(line[end])) {
				end++
			}
			fields = append(fields, line[i:end])
			i = end
			continue
		}
	}

	return fields
}

func (t task) String() string {
	dates := make([]string, 0, len(t.dates))
	for _, date := range t.dates {
		dates = append(dates, date.Format("Mon 15:04"))
	}

	return fmt.Sprintf("<%s: %s - %#v>", t.title, t.duration, dates)
}

const timeLayout = "Monday, 15:04"

func main() {
	if len(os.Args) != 2 {
		fmt.Println("You need an argument (the tasks).")
		os.Exit(2)
	}
	file, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	tasks, err := loadTasks(file)
	if err != nil {
		panic(err)
	}
	file.Close()

	fmt.Println("Current time is:", time.Now().Format(timeLayout))

	fmt.Println("\nYou next tasks are (in 30min):")
	for _, task := range tasks {
		for _, date := range task.dates {
			if date.Weekday() != time.Now().Weekday() {
				continue
			}

			const minute = time.Second * 60
			const hour = minute * 60

			taskTime := time.Duration(hour*time.Duration(date.Hour()) + minute*time.Duration(date.Minute()))
			currentTime := time.Duration(hour*time.Duration(time.Now().Hour()) + minute*time.Duration(time.Now().Minute()))

			if currentTime < taskTime-minute*30 {
				continue
			}

			if currentTime < taskTime {
				fmt.Printf("\t- %s in %s (%s).\n", task.title, taskTime-currentTime, task.duration)
				continue
			}

			if currentTime < taskTime+task.duration {
				fmt.Printf("\t- %s (%s).\n", task.title, taskTime+task.duration-currentTime)
			}
		}
	}

	fmt.Println("\nYou tasks for today are:")
	for _, task := range tasks {
		for _, date := range task.dates {
			if date.Weekday() != time.Now().Weekday() {
				continue
			}

			fmt.Printf("\t- %s (%s).\n", task.title, task.duration)
		}
	}
}
