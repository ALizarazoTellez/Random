package main

import (
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
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

	dirname, err := os.MkdirTemp(os.TempDir(), "alt-uploader-*")
	if err != nil {
		panic(err)
	}
	fmt.Printf("Data directory: %q.\n", dirname)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `
<!doctype html>
<html>
<head>
	<meta charset=utf-8>
	<meta name=viewport content=initial-scale=1>
</head>
<body>
	<h1> Uploader </h1>
	<form action=/upload method=post enctype=multipart/form-data>
		<input name=file type=file>
		<button> Upload </button>
	</form>

	<h1> Downloader </h1>
	<ul>`)

		files, err := os.ReadDir(dirname)
		if err != nil {
			panic(err)
		}

		for _, file := range files {
			fmt.Fprintf(w, "<li><a href='/download/%s' download>%s</a></li>", file.Name(), file.Name())
		}

		fmt.Fprint(w, "</ul></body></html>")
	})

	http.HandleFunc("POST /upload", func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseMultipartForm(1024 * 1024 * 100); err != nil {
			panic(err)
		}

		remoteFile, err := r.MultipartForm.File["file"][0].Open()
		if err != nil {
			panic(err)
		}
		defer remoteFile.Close()

		localFile, err := os.Create(filepath.Join(dirname, r.MultipartForm.File["file"][0].Filename))
		if err != nil {
			panic(err)
		}
		defer localFile.Close()

		if _, err := io.Copy(localFile, remoteFile); err != nil {
			panic(err)
		}
	})

	http.HandleFunc("/download/", func(w http.ResponseWriter, r *http.Request) {
		filename := r.URL.Path[len("/download/"):]

		localFile, err := os.Open(filepath.Join(dirname, filename))
		if err != nil {
			panic(err)
		}
		defer localFile.Close()

		if _, err := io.Copy(w, localFile); err != nil {
			panic(err)
		}
	})

	addr := publicIP.String() + ":1234"
	fmt.Printf("Serving on: %q...\n", addr)
	fmt.Println(http.ListenAndServe(addr, nil))
}
