package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"
	"unicode"
)

type dayMoment struct {
	weekday time.Weekday
	hour    int
	minute  int
}

func newDayMoment(t time.Time) dayMoment {
	return dayMoment{
		weekday: t.Weekday(),
		hour:    t.Hour(),
		minute:  t.Minute(),
	}
}

func (d dayMoment) String() string {
	return fmt.Sprintf("<%s %d:%d>", d.weekday, d.hour, d.minute)
}

func (d dayMoment) difference(d2 dayMoment) time.Duration {
	if d.weekday != d2.weekday {
		panic("must be same days")
	}

	const minute = time.Second * 60
	const hour = minute * 60

	return hour*time.Duration(d.hour) + minute*time.Duration(d.minute) -
		(hour*time.Duration(d2.hour) + minute*time.Duration(d2.minute))
}

func (d dayMoment) after(d2 dayMoment) bool {
	return d2.before(d)
}

func (d dayMoment) before(d2 dayMoment) bool {
	if d.weekday < d2.weekday {
		return true
	}

	if d.weekday > d2.weekday {
		return false
	}

	if d.hour < d2.hour {
		return true
	}

	if d.hour > d2.hour {
		return false
	}

	if d.minute < d2.minute {
		return true
	}

	return false
}

func (d dayMoment) addDuration(duration time.Duration) dayMoment {
	const minute = time.Second * 60
	const hour = minute * 60

	dayDuration := hour*time.Duration(d.hour) + minute*time.Duration(d.minute)
	dayDuration += duration

	d.hour = int(dayDuration.Hours())
	d.minute = int((dayDuration - time.Duration(dayDuration.Hours())*hour).Minutes())

	return d
}

type task struct {
	title      string
	duration   time.Duration
	dayMoments []dayMoment
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
		days := make([]dayMoment, 0, len(fields[2:]))
		for _, rawDay := range fields[2:] {
			// Global day marker.
			if rawDay[0] == '*' {
				t, err := time.Parse("* 15:04", rawDay)
				if err != nil {
					return nil, err
				}

				for i := range 7 {
					days = append(days, dayMoment{weekday: time.Monday + time.Weekday(i), hour: t.Hour(), minute: t.Minute()})
				}

				continue
			}

			t, err := time.Parse("Mon 15:04", rawDay)
			if err != nil {
				return nil, err
			}

			day := dayMoment{hour: t.Hour(), minute: t.Minute()}

			switch rawDay[:3] {
			case "Mon":
				day.weekday = time.Monday
			case "Tue":
				day.weekday = time.Tuesday
			case "Wed":
				day.weekday = time.Wednesday
			case "Thu":
				day.weekday = time.Thursday
			case "Fri":
				day.weekday = time.Friday
			case "Sat":
				day.weekday = time.Saturday
			case "Sun":
				day.weekday = time.Sunday
			default:
				panic("unknown " + rawDay[:3])
			}

			days = append(days, day)
		}

		tasks = append(tasks, task{title: fields[0], duration: duration, dayMoments: days})
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
	return fmt.Sprintf("<%s: %s - %#v>", t.title, t.duration, t.dayMoments)
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
	currentTime := time.Now()
	currentDayMoment := newDayMoment(currentTime)

	for _, task := range tasks {
		for _, taskDayMoment := range task.dayMoments {
			if taskDayMoment.weekday != currentDayMoment.weekday {
				continue
			}

			if taskDayMoment.addDuration(task.duration).before(currentDayMoment) {
				continue
			}

			if currentDayMoment.after(taskDayMoment) {
				fmt.Printf("\t- %s [%s].\n", task.title, taskDayMoment.addDuration(task.duration).difference(currentDayMoment))
				continue
			}

			if currentDayMoment.addDuration(time.Second * 60 * 30).after(taskDayMoment) {
				fmt.Printf("\t- %s in %s (%s).\n", task.title, taskDayMoment.difference(currentDayMoment), task.duration)
				continue
			}

		}
	}

	fmt.Println("\nYou tasks for today are:")
	for _, task := range tasks {
		for _, taskDayMoment := range task.dayMoments {
			if taskDayMoment.weekday != currentDayMoment.weekday {
				continue
			}

			if currentDayMoment.after(taskDayMoment.addDuration(task.duration)) {
				continue
			}

			fmt.Printf("\t- %s (%s).\n", task.title, task.duration)
		}
	}
}
