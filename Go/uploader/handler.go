package main

import (
	"embed"
	"fmt"
	"html/template"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

//go:embed frontend/*
var frontend embed.FS

var templates = template.Must(template.New("templates").ParseFS(frontend, "frontend/*.html.gotmpl"))

type handlerSet struct {
	storage string
}

func (h handlerSet) home(w http.ResponseWriter, r *http.Request) {
	files, err := os.ReadDir(h.storage)
	if err != nil {
		panic(err)
	}

	names := make([]string, len(files))
	for i, file := range files {
		names[i] = file.Name()
	}

	if r.Header.Get("HX-Request") == "true" {
		templates.ExecuteTemplate(w, "download-links", names)
	} else {
		templates.ExecuteTemplate(w, "index.html.gotmpl", names)
	}
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

	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	if _, err := io.Copy(w, localFile); err != nil {
		panic(err)
	}
}

func (h handlerSet) htmx(w http.ResponseWriter, r *http.Request) {
	http.ServeFileFS(w, r, frontend, "frontend/htmx.min.js")
}
