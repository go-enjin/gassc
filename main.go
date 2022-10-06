package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/wellington/go-libsass"
)

func process(src string) error {
	r, err := os.Open(src)
	if err != nil {
		return err
	}
	comp, err := libsass.New(os.Stdout, r)
	if err != nil {
		return err
	}

	dir := filepath.Dir(src)
	if err := comp.Option(libsass.IncludePaths([]string{dir})); err != nil {
		return err
	}

	if err := comp.Run(); err != nil {
		return err
	}

	return nil
}

func usage() {
	fmt.Printf("usage: %v file.scss [files.scss...]\n", os.Args[0])
	os.Exit(1)
}

func main() {
	if len(os.Args) == 1 {
		usage()
	}
	for _, arg := range os.Args[1:] {
		switch strings.ToLower(arg) {
		case "-h", "--help":
			usage()
		}
	}
	for idx, path := range os.Args {
		if idx == 0 {
			continue
		}
		if err := process(path); err != nil {
			log.Fatal(err)
		}
	}
}