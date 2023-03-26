#!/usr/bin/make --no-print-directory --jobs=1 --environment-overrides -f

# Copyright (c) 2023  The Go-Enjin Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#: uncomment to echo instead of execute
#CMD=echo

-include .env
#export

.PHONY: all help
.PHONY: clean distclean realclean
.PHONY: local unlocal tidy be-update
.PHONY: debug build build-all build-amd64 build-arm64
.PHONY: release release-all release-amd64 release-arm64
.PHONY: install install-autocomplete

BIN_NAME ?= gassc
UNTAGGED_VERSION ?= v0.2.4
UNTAGGED_COMMIT ?= 0000000000

CLEAN_FILES     ?= "${BIN_NAME}" ${BIN_NAME}.*.* pprof.{proxy,repos,watch}
DISTCLEAN_FILES ?=
REALCLEAN_FILES ?=

BUILD_VERSION_VAR := main.Version
BUILD_RELEASE_VAR := main.Release

include Golang.cmd.mk

help:
	@echo "usage: make <help|clean|tidy>"
	@echo "       make <debug>"
	@echo "       make <build|build-amd64|build-arm64|build-all>"
	@echo "       make <release|release-amd64|release-arm64|release-all>"
	@echo "       make <install>"
	@echo "       make <install-autocomplete>"

clean:
	@$(call __clean,${CLEAN_FILES})

distclean: clean
	@$(call __clean,${DISTCLEAN_FILES})

realclean: distclean
	@$(call __clean,${REALCLEAN_FILES})

debug: BUILD_VERSION=$(call __tag_ver)
debug: BUILD_RELEASE=$(call __rel_ver)
debug: TRIM_PATHS=$(call __go_trim_path)
debug:
	@$(call __go_build_debug,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}",${BUILD_OS},${BUILD_ARCH},.)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}"

build: BUILD_VERSION=$(call __tag_ver)
build: BUILD_RELEASE=$(call __rel_ver)
build: TRIM_PATHS=$(call __go_trim_path)
build:
	@$(call __go_build_release,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}",${BUILD_OS},${BUILD_ARCH},.)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}"

build-amd64: BUILD_VERSION=$(call __tag_ver)
build-amd64: BUILD_RELEASE=$(call __rel_ver)
build-amd64: TRIM_PATHS=$(call __go_trim_path)
build-amd64:
	@$(call __go_build_release,"${BIN_NAME}.${BUILD_OS}.amd64",${BUILD_OS},amd64,.)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.amd64"

build-arm64: BUILD_VERSION=$(call __tag_ver)
build-arm64: BUILD_RELEASE=$(call __rel_ver)
build-arm64: TRIM_PATHS=$(call __go_trim_path)
build-arm64:
	@$(call __go_build_release,"${BIN_NAME}.${BUILD_OS}.arm64",${BUILD_OS},arm64,.)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.arm64"

build-all: build-amd64 build-arm64

release: build
	@$(call __upx_build,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}")

release-arm64: build-arm64
	@$(call __upx_build,"${BIN_NAME}.${BUILD_OS}.arm64")

release-amd64: build-amd64
	@$(call __upx_build,"${BIN_NAME}.${BUILD_OS}.amd64")

release-all: release-amd64 release-arm64

install:
	@if [ -f "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}" ]; then \
		echo "# ${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH} present"; \
		$(call __install_exe,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}","${INSTALL_BIN_PATH}/${BIN_NAME}"); \
	else \
		echo "error: missing ${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH} binary" 1>&2; \
	fi

install-arm64:
	@if [ -f "${BIN_NAME}.${BUILD_OS}.arm64" ]; then \
		echo "# ${BIN_NAME}.${BUILD_OS}.arm64 present"; \
		$(call __install_exe,"${BIN_NAME}.${BUILD_OS}.arm64","${INSTALL_BIN_PATH}/${BIN_NAME}"); \
	else \
		echo "error: missing ${BIN_NAME}.${BUILD_OS}.arm64 binary" 1>&2; \
	fi

install-amd64:
	@if [ -f "${BIN_NAME}.${BUILD_OS}.amd64" ]; then \
		echo "# ${BIN_NAME}.${BUILD_OS}.amd64 present"; \
		$(call __install_exe,"${BIN_NAME}.${BUILD_OS}.amd64","${INSTALL_BIN_PATH}/${BIN_NAME}"); \
	else \
		echo "error: missing ${BIN_NAME}.${BUILD_OS}.amd64 binary" 1>&2; \
	fi

install-autocomplete: GASSC_AUTOCOMPLETE_FILE=${INSTALL_AUTOCOMPLETE_PATH}/${BIN_NAME}
install-autocomplete:
	@$(call __install_exe,./bash_autocomplete,${GASSC_AUTOCOMPLETE_FILE})

#local: __local

#unlocal: __unlocal

tidy: __tidy

#be-update: __be_update
