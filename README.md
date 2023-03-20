# gassc - Go-Enjin libsass compiler

This is the SCSS compiler used by `enjenv` and Go-Enjin projects in general.

# Installation

``` shell
$ go install github.com/go-enjin/gassc@latest
```

# Usage

``` shell
$ gassc
NAME:
   gassc - go-enjin sass compiler

USAGE:
   gassc [options] source.scss [sources...]

VERSION:
   0.1.0

DESCRIPTION:
   Simple libsass compiler used by the go-enjin project

AUTHOR:
   The Go-Enjin Team <go.enjin.org@gmail.com>

COMMANDS:
   help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --comments                                     include comments with output (default: false)
   --font-dir value                               specify where to find fonts
   --include-path value [ --include-path value ]  add compiler include paths
   --output-style value                           set presentation of css output, must be one of: nested, expanded, compact or compressed
   --precision value                              specify the floating point precision preserved during math operations (default: 0)
   --sass-syntax                                  use sass syntax, scss is default (default: false)
   --help, -h                                     show help (default: false)
   --version, -v                                  print the version (default: false)
```

# Authors

The Go-Enjin Team

# License

Apache 2.0, see LICENSE.md.
