package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/urfave/cli/v2"
	"github.com/wellington/go-libsass"
)

var (
	Version = "0.1.0"
)

func main() {
	app := &cli.App{
		Name:        "gassc",
		Usage:       "go-enjin sass compiler",
		UsageText:   "gassc [options] source.scss [sources...]",
		Description: "Simple libsass compiler used by the go-enjin project",
		Authors: []*cli.Author{{
			Name:  "The Go-Enjin Team",
			Email: "go.enjin.org@gmail.com",
		}},
		Version: Version,
		Action:  action,
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:  "comments",
				Usage: "include comments with output",
			},
			&cli.PathFlag{
				Name:  "font-dir",
				Usage: "specify where to find fonts",
			},
			&cli.StringSliceFlag{
				Name:  "include-path",
				Usage: "add compiler include paths",
			},
			&cli.StringFlag{
				Name:  "output-style",
				Usage: "set presentation of css output, must be one of: nested, expanded, compact or compressed",
			},
			&cli.IntFlag{
				Name:  "precision",
				Usage: "specify the floating point precision preserved during math operations",
			},
			&cli.BoolFlag{
				Name:  "sass-syntax",
				Usage: "use sass syntax, scss is default",
			},
		},
	}
	if err := app.Run(os.Args); err != nil {
		fmt.Printf("error: %v", err)
		os.Exit(1)
	}
}

func action(ctx *cli.Context) (err error) {
	if ctx.NArg() == 0 {
		cli.ShowAppHelpAndExit(ctx, 1)
	}
	for idx, path := range os.Args {
		if idx == 0 {
			continue
		}
		if err = process(ctx, path); err != nil {
			return
		}
	}
	return
}

func process(ctx *cli.Context, src string) (err error) {
	var r *os.File
	if r, err = os.Open(src); err != nil {
		return
	}

	var comp libsass.Compiler
	if comp, err = libsass.New(os.Stdout, r); err != nil {
		return
	}

	if ctx.Bool("comments") {
		if err = comp.Option(libsass.Comments(true)); err != nil {
			return
		}
	}

	if fontDir := ctx.Path("font-dir"); fontDir != "" {
		if err = comp.Option(libsass.FontDir(fontDir)); err != nil {
			return
		}
	}

	if outputStyleName := ctx.String("output-style"); outputStyleName != "" {
		var outputStyle int
		switch strings.ToLower(outputStyleName) {
		case "nested":
			outputStyle = libsass.NESTED_STYLE
		case "compact":
			outputStyle = libsass.COMPACT_STYLE
		case "expanded":
			outputStyle = libsass.EXPANDED_STYLE
		case "compressed":
			outputStyle = libsass.COMPRESSED_STYLE
		default:
			err = fmt.Errorf("invalid output-style: %v, must be one of: nested, compact, expanded or compressed", outputStyleName)
			return
		}
		if err = comp.Option(libsass.OutputStyle(outputStyle)); err != nil {
			return
		}
	}

	includePaths := ctx.StringSlice("include-path")
	includePaths = append(includePaths, filepath.Dir(src))
	includePathsOption := libsass.IncludePaths(includePaths)
	if err = comp.Option(includePathsOption); err != nil {
		return
	}

	err = comp.Run()
	return
}