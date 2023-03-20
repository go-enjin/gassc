package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/bep/golibsass/libsass"
	"github.com/urfave/cli/v2"
)

var (
	Version = "0.2.0"
)

func main() {
	app := &cli.App{
		Name:        "gassc",
		Usage:       "go-enjin sass compiler",
		UsageText:   "gassc [options] <source.scss>",
		Description: "Simple libsass compiler used by the go-enjin project",
		Authors: []*cli.Author{{
			Name:  "The Go-Enjin Team",
			Email: "go.enjin.org@gmail.com",
		}},
		Version: Version,
		Action:  action,
		Flags: []cli.Flag{
			&cli.PathFlag{
				Name:    "output-file",
				Usage:   "specify file to write, use \"-\" for stdout",
				Value:   "-",
				Aliases: []string{"O"},
			},
			&cli.StringFlag{
				Name:    "output-style",
				Usage:   "set presentation of css output, must be one of: nested, expanded, compact or compressed",
				Value:   "nested",
				Aliases: []string{"S"},
			},
			&cli.StringSliceFlag{
				Name:    "include-path",
				Usage:   "add compiler include paths",
				Aliases: []string{"I"},
			},
			&cli.BoolFlag{
				Name:    "no-source-map",
				Usage:   "do not include source-map output (embedded when output-file is \"-\")",
				Aliases: []string{"M"},
			},
			&cli.BoolFlag{
				Name:    "sass-syntax",
				Usage:   "use sass syntax, scss is default",
				Aliases: []string{"A"},
			},
			&cli.IntFlag{
				Name:    "precision",
				Usage:   "specify the floating point precision preserved during math operations",
				Value:   10,
				Aliases: []string{"P"},
			},
			&cli.BoolFlag{
				Name:  "release",
				Usage: "same as: --no-source-map --output-style=compressed",
			},
		},
	}
	if err := app.Run(os.Args); err != nil {
		fmt.Printf("error: %v", err)
		os.Exit(1)
	}
}

func action(ctx *cli.Context) (err error) {
	if ctx.NArg() != 1 {
		cli.ShowAppHelpAndExit(ctx, 1)
	}
	if err = process(ctx, ctx.Args().First()); err != nil {
		return
	}
	return
}

func process(ctx *cli.Context, src string) (err error) {

	var data []byte
	if data, err = os.ReadFile(src); err != nil {
		return
	}
	contents := string(data)

	releaseMode := ctx.Bool("release")

	outputFile := ctx.Path("output-file")
	if outputFile == "" {
		outputFile = "-"
	}
	outputStyle := ctx.String("output-style")
	if releaseMode {
		outputStyle = "compressed"
	}

	includePaths := ctx.StringSlice("include-path")
	includePaths = append(includePaths, filepath.Dir(src))
	options := libsass.Options{
		IncludePaths: includePaths,
		Precision:    ctx.Int("precision"),
		SassSyntax:   ctx.Bool("sass-syntax"),
		OutputStyle:  libsass.ParseOutputStyle(outputStyle),
	}

	if !releaseMode && !ctx.Bool("no-source-map") {
		if outputFile == "-" {
			options.SourceMapOptions = libsass.SourceMapOptions{
				Contents:       true,
				OmitURL:        true,
				EnableEmbedded: true,
			}
		} else {
			options.SourceMapOptions = libsass.SourceMapOptions{
				Filename:       outputFile + ".map",
				Contents:       true,
				OmitURL:        true,
				EnableEmbedded: false,
			}
		}
	}

	var transpiler libsass.Transpiler
	if transpiler, err = libsass.New(options); err != nil {
		err = fmt.Errorf("error constructing transpilier: %v", err)
		return
	}

	var result libsass.Result
	if result, err = transpiler.Execute(contents); err != nil {
		err = fmt.Errorf("error transipiling: %v", err)
		return
	}

	if outputFile == "" || outputFile == "-" {
		_, _ = fmt.Fprint(os.Stdout, result.CSS)
		return
	}
	if err = os.WriteFile(outputFile, []byte(result.CSS), 0660); err != nil {
		err = fmt.Errorf("error writing output-file: %v", err)
		return
	}
	if result.SourceMapFilename != "" && result.SourceMapContent != "" {
		if err = os.WriteFile(result.SourceMapFilename, []byte(result.SourceMapContent), 0660); err != nil {
			err = fmt.Errorf("error writing sourcemap file: %v - %v", result.SourceMapFilename, err)
			return
		}
	}
	return
}