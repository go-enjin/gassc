# gassc - Go-Enjin libsass compiler

This is the SCSS compiler used by Go-Enjin theme features.

# Installation

## plain Go install

``` shell
$ go install github.com/go-enjin/gassc@latest
```

## apt install

``` shell
$ wget https://apt.go-enjin.org/apt-go-enjin-org_latest.deb
$ sudo dpkg -i ./apt-go-enjin-org_latest.deb
$ sudo apt update && sudo apt install gassc
```

## homebrew install

``` shell
$ brew tap go-enjin/tap
$ brew install gassc
```

# Usage

``` shell
$ gassc --help
NAME:
   gassc - go-enjin sass compiler

USAGE:
   gassc [options] <source.scss>

VERSION:
   v0.2.4 (00commit00) [00shasum00]

DESCRIPTION:
   Simple libsass compiler used by the go-enjin project

AUTHOR:
   The Go-Enjin Team <go.enjin.org@gmail.com>

GLOBAL OPTIONS:
   --help, -h                                                         show help (default: false)
   --include-path value, -I value [ --include-path value, -I value ]  add compiler include paths
   --no-source-map, -M                                                do not include source-map output (embedded when output-file is "-") (default: false)
   --output-file value, -O value                                      specify file to write, use "-" for stdout (default: "-")
   --output-style value, -S value                                     set presentation of css output, must be one of: nested, expanded, compact or compressed (default: "nested")
   --precision value, -P value                                        specify the floating point precision preserved during math operations (default: 10)
   --release                                                          same as: --no-source-map --output-style=compressed (default: false)
   --sass-syntax, -A                                                  use sass syntax, scss is default (default: false)
   --version, -v                                                      print the version (default: false)
```

# Authors

The Go-Enjin Team

# License

Apache 2.0, see the LICENSE.md file.
