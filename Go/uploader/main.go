package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
)

func main() {
	hostname, err := os.Hostname()
	if err != nil {
		panic(err)
	}

	fmt.Println("Hostname:", hostname)

	ips, err := net.LookupIP(hostname)
	if err != nil {
		panic(err)
	}

	publicIP := net.IP(nil)
	for _, ip := range ips {
		fmt.Printf("Testing %q... ", ip)

		if ip.To4() == nil {
			fmt.Println("Skipped because is not IPv4.")
			continue
		}
		if ip.IsLoopback() {
			fmt.Println("Skipped because is loopback.")
			continue
		}

		publicIP = ip
		break
	}

	if publicIP == nil {
		fmt.Println("Checking environment variable `BINDADDR`...")
		publicIP = net.ParseIP(os.Getenv("BINDADDR")).To4()
	}
	if publicIP == nil {
		fmt.Println("No valid IP found!")
		os.Exit(2)
	}
	fmt.Println("Selected.")

	storage, err := os.MkdirTemp(os.TempDir(), "alt-uploader-*")
	if err != nil {
		panic(err)
	}
	fmt.Printf("Data directory: %q.\n", storage)

	handlers := handlerSet{storage: storage}
	http.HandleFunc("/", handlers.home)
	http.HandleFunc("/download/", handlers.download)
	http.HandleFunc("POST /upload", handlers.postUpload)

	addr := publicIP.String() + ":1234"
	fmt.Printf("Serving on: %q...\n", addr)
	go func() { fmt.Println(http.ListenAndServe(addr, nil)) }()

	signalInterrupt := make(chan os.Signal, 1)
	signal.Notify(signalInterrupt, os.Interrupt)
	<-signalInterrupt

	if err := os.RemoveAll(storage); err != nil {
		panic(err)
	}

	fmt.Println("Cleanup done.")
}
