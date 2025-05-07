package main

import (
	"os"
	"time"
)

func init() {
	// Fix locale on Android. Use TZ envar.
	loc, err := time.LoadLocation(os.Getenv("TZ"))
	if err != nil {
		println("Error trying to get timezone...")
	}

	time.Local = loc
}
