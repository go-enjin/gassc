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
UNTAGGED_VERSION ?= v0.2.2
UNTAGGED_COMMIT ?= 0000000000

PWD = $(shell pwd)
SHELL = /bin/bash

BUILD_OS   := $(shell uname -s | awk '{print $$1}' | perl -pe '$$_=lc($$_)')
BUILD_ARCH := $(shell uname -m | perl -pe 's!aarch64!arm64!;s!x86_64!amd64!;')

prefix ?= /usr

GIT_STATUS := $([ -d .git ] && git status 2> /dev/null)

CLEAN_FILES     ?= "${BIN_NAME}" ${BIN_NAME}.*.* pprof.{proxy,repos,watch}
DISTCLEAN_FILES ?=
REALCLEAN_FILES ?=

UPX_BIN := $(shell which upx)

SHASUM_BIN := $(shell which shasum)
SHASUM_CMD := ${SHASUM_BIN} -a 256

define _trim_path
$(shell \
if [ "${GOPATH}" != "" ]; then \
	echo "${GOPATH};${PWD}"; \
else \
	echo "${PWD}"; \
fi)
endef

define _tag_ver
$(shell ([ -d .git ] && git describe 2> /dev/null) || echo "${UNTAGGED_VERSION}")
endef

define _rel_ver
$(shell \
	if [ -d .git ]; then \
		if [ -z "${GIT_STATUS}" ]; then \
			git rev-parse --short=10 HEAD; \
		else \
			[ -d .git ] && git diff 2> /dev/null \
				| ${SHASUM_CMD} - 2> /dev/null \
				| perl -pe 's!^\s*([a-f0-9]{10}).*!\1!'; \
		fi; \
	else \
		echo "${UNTAGGED_COMMIT}"; \
	fi \
)
endef


# 1: bin-name, 2: goos, 3: goarch, 4: ldflags, 5: gcflags, 6: asmflags, 7: argv
define _cmd_go_build
$(shell echo "\
GOOS=\"$(2)\" GOARCH=\"$(3)\" \
go build -v \
		-o \"$(1)\" \
		-ldflags=\"$(4) \
-buildid='' \
-X 'main.Version=${BUILD_VERSION}' \
-X 'main.Release=${BUILD_RELEASE}' \
\" \
		-gcflags=\"$(5)\" \
		-asmflags=\"$(6)\" \
		$(7) \
		.")
endef

# 1: bin-name, 2: goos, 3: goarch, 4: ldflags
define _cmd_go_build_trimpath
$(call _cmd_go_build,$(1),$(2),$(3),$(4),-trimpath='${TRIM_PATHS}',-trimpath='${TRIM_PATHS}',-trimpath)
endef

# 1: bin-name, 2: goos, 3: goarch
define _build_target
	echo "# building $(2)-$(3) (release): ${BIN_NAME} (${BUILD_VERSION}, ${BUILD_RELEASE})"; \
	echo $(call _cmd_go_build_trimpath,$(1),$(2),$(3),-s -w); \
	$(call _cmd_go_build_trimpath,$(1),$(2),$(3),-s -w)
endef

# 1: bin-name, 2: goos, 3: goarch
define _build_debug
	echo "# building $(2)-$(3) (debug): ${BIN_NAME} (${BUILD_VERSION}, ${BUILD_RELEASE})"; \
	echo $(call _cmd_go_build,$(1),$(2),$(3),,-N -l); \
	$(call _cmd_go_build,$(1),$(2),$(3),,-N -l)
endef

define _upx_build
	if [ "${BUILD_OS}" == "darwin" ]; then \
		echo "# upx command not supported on darwin, nothing to do"; \
	elif [ -n "${UPX_BIN}" -a -x "${UPX_BIN}" ]; then \
		echo -n "# packing: $(1) - "; \
		du -hs "$(1)" | awk '{print $$1}'; \
		${UPX_BIN} -qq -7 --no-color --no-progress "$(1)"; \
		echo -n "# packed: $(1) - "; \
		du -hs "$(1)" | awk '{print $$1}'; \
		${SHASUM_CMD} "$(1)"; \
	else \
		echo "# upx command not found, nothing to do"; \
	fi
endef

define _clean
	for FOUND in $(1); do \
		if [ -n "$${FOUND}" ]; then \
			rm -rfv $${FOUND}; \
		fi; \
	done
endef

help:
	@echo "usage: make <help|clean|local|unlocal|tidy>"
	@echo "       make <debug>"
	@echo "       make <build|build-amd64|build-arm64|build-all>"
	@echo "       make <release|release-amd64|release-arm64|release-all>"
	@echo "       make <install>"
	@echo "       make <install-autocomplete>"

clean:
	@$(call _clean,${CLEAN_FILES})

distclean: clean
	@$(call _clean,${DISTCLEAN_FILES})

realclean: distclean
	@$(call _clean,${REALCLEAN_FILES})

debug: BUILD_VERSION=$(call _tag_ver)
debug: BUILD_RELEASE=$(call _rel_ver)
debug: TRIM_PATHS=$(call _trim_path)
debug: export CGO_ENABLED=1
ifeq (${BUILD_OS},linux)
ifeq (${BUILD_ARCH},arm64)
debug: export CC=aarch64-linux-gnu-gcc
debug: export CXX=aarch64-linux-gnu-g++
else
debug: export CC=x86_64-linux-gnu-gcc
debug: export CXX=x86_64-linux-gnu-g++
endif
endif
debug:
	@$(call _build_debug,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}",${BUILD_OS},${BUILD_ARCH})
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}"

build: BUILD_VERSION=$(call _tag_ver)
build: BUILD_RELEASE=$(call _rel_ver)
build: TRIM_PATHS=$(call _trim_path)
build: export CGO_ENABLED=1
ifeq (${BUILD_OS},linux)
ifeq (${BUILD_ARCH},arm64)
build: export CC=aarch64-linux-gnu-gcc
build: export CXX=aarch64-linux-gnu-g++
else
build: export CC=x86_64-linux-gnu-gcc
build: export CXX=x86_64-linux-gnu-g++
endif
endif
build:
	@$(call _build_target,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}",${BUILD_OS},${BUILD_ARCH})
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}"

build-amd64: BUILD_VERSION=$(call _tag_ver)
build-amd64: BUILD_RELEASE=$(call _rel_ver)
build-amd64: TRIM_PATHS=$(call _trim_path)
build-amd64: export CGO_ENABLED=1
ifeq (${BUILD_OS},linux)
build-amd64: export CC=x86_64-linux-gnu-gcc
build-amd64: export CXX=x86_64-linux-gnu-g++
endif
build-amd64:
	@$(call _build_target,"${BIN_NAME}.${BUILD_OS}.amd64",${BUILD_OS},amd64)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.amd64"

build-arm64: BUILD_VERSION=$(call _tag_ver)
build-arm64: BUILD_RELEASE=$(call _rel_ver)
build-arm64: TRIM_PATHS=$(call _trim_path)
build-arm64: export CGO_ENABLED=1
ifeq (${BUILD_OS},linux)
build-arm64: export CC=aarch64-linux-gnu-gcc
build-arm64: export CXX=aarch64-linux-gnu-g++
endif
build-arm64:
	@$(call _build_target,"${BIN_NAME}.${BUILD_OS}.arm64",${BUILD_OS},arm64)
	@${SHASUM_CMD} "${BIN_NAME}.${BUILD_OS}.arm64"

build-all: build-amd64 build-arm64

release: build
	@$(call _upx_build,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}")

release-arm64: build-arm64
	@$(call _upx_build,"${BIN_NAME}.${BUILD_OS}.arm64")

release-amd64: build-amd64
	@$(call _upx_build,"${BIN_NAME}.${BUILD_OS}.amd64")

release-all: release-amd64 release-arm64

define _install_build
	BIN_PATH="${DESTDIR}${prefix}/bin"; \
	echo "# installing $(1) to: $${BIN_PATH}/$(2)"; \
	[ -d "$${BIN_PATH}" ] || mkdir -vp "$${BIN_PATH}"; \
	${CMD} /usr/bin/install -v -m 0775 "$(1)" "$${BIN_PATH}/$(2)"; \
	${CMD} ${SHASUM_CMD} "$${BIN_PATH}/$(2)";
endef

install:
	@if [ -f "${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}" ]; then \
		echo "# ${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH} present"; \
		$(call _install_build,"${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH}","${BIN_NAME}") \
	else \
		echo "error: missing ${BIN_NAME}.${BUILD_OS}.${BUILD_ARCH} binary" 1>&2; \
	fi

install-autocomplete: ETC_PATH=${DESTDIR}/etc
install-autocomplete: AUTOCOMPLETE_PATH=${ETC_PATH}/bash_completion.d
install-autocomplete: GASSC_AUTOCOMPLETE_FILE=${AUTOCOMPLETE_PATH}/${BIN_NAME}
install-autocomplete:
	@[ -d "${AUTOCOMPLETE_PATH}" ] || mkdir -vp "${AUTOCOMPLETE_PATH}"
	@echo "# installing ${BIN_NAME} bash_autocomplete to: ${GASSC_AUTOCOMPLETE_FILE}"
	@${CMD} /usr/bin/install -v -m 0775 "./bash_autocomplete" "${GASSC_AUTOCOMPLETE_FILE}"
	@${CMD} ${SHASUM_CMD} "${ENJENV_AUTOCOMPLETE_FILE}"
