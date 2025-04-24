package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

type handlerSet struct {
	storage string
}

func (h handlerSet) home(w http.ResponseWriter, r *http.Request) {
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

	files, err := os.ReadDir(h.storage)
	if err != nil {
		panic(err)
	}

	for _, file := range files {
		fmt.Fprintf(w, "<li><a href='/download/%s' download>%s</a></li>", file.Name(), file.Name())
	}

	fmt.Fprint(w, "</ul></body></html>")
}

func (h handlerSet) postUpload(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(1024 * 1024 * 100); err != nil {
		panic(err)
	}

	remoteFile, err := r.MultipartForm.File["file"][0].Open()
	if err != nil {
		panic(err)
	}
	defer remoteFile.Close()

	localFile, err := os.Create(filepath.Join(h.storage, r.MultipartForm.File["file"][0].Filename))
	if err != nil {
		panic(err)
	}
	defer localFile.Close()

	if _, err := io.Copy(localFile, remoteFile); err != nil {
		panic(err)
	}
}

func (h handlerSet) download(w http.ResponseWriter, r *http.Request) {
	filename := r.URL.Path[len("/download/"):]

	localFile, err := os.Open(filepath.Join(h.storage, filename))
	if err != nil {
		panic(err)
	}
	defer localFile.Close()

	if _, err := io.Copy(w, localFile); err != nil {
		panic(err)
	}
}
