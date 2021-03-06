# This file is part of MXE.
# See index.html for further information.

PKG             := go
$(PKG)_WEBSITE  := https://golang.org/
$(PKG)_OWNER    := https://github.com/starius
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.6.2
$(PKG)_CHECKSUM := 787b0b750d037016a30c6ed05a8a70a91b2e9db4bd9b1a2453aa502a63f1bccc
$(PKG)_SUBDIR   := go
$(PKG)_FILE     := go$($(PKG)_VERSION).src.tar.gz
$(PKG)_URL      := https://storage.googleapis.com/golang/$($(PKG)_FILE)
$(PKG)_DEPS     :=

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://golang.org/dl/' | \
    $(SED) -n 's,.*go\(1.6.[0-9][^>]*\)\.src\.tar.*,\1,p' | \
    $(SORT) -h | tail -1
endef

define $(PKG)_BUILD
    cd '$(1)/src' && \
        GOROOT_BOOTSTRAP='$(PREFIX)/$(BUILD)/go' \
        GOROOT_FINAL='$(PREFIX)/$(TARGET)/go' \
        GOOS=windows \
        GOARCH='$(if $(findstring x86_64,$(TARGET)),amd64,386)' \
        DYLD_INSERT_LIBRARIES= \
        ./make.bash

    mkdir -p '$(PREFIX)/$(TARGET)/go'
    for d in include src bin pkg; do \
        cp -a '$(1)'/$$d '$(PREFIX)/$(TARGET)/go/' ; \
    done

    #create prefixed go wrapper script
    mkdir -p '$(PREFIX)/bin/$(TARGET)'
    (echo '#!/usr/bin/env bash'; \
     echo 'echo "== Using MXE Go wrapper: $(PREFIX)/bin/$(TARGET)-go"'; \
     echo 'set -xue'; \
     echo 'CGO_ENABLED=1 \'; \
     echo 'GOOS=windows \'; \
     echo 'GOARCH=$(if $(findstring x86_64,$(TARGET)),amd64,386) \'; \
     echo 'DYLD_INSERT_LIBRARIES= \'; \
     echo 'CC=$(PREFIX)/bin/$(TARGET)-gcc \'; \
     echo 'CXX=$(PREFIX)/bin/$(TARGET)-g++ \'; \
     echo 'PKG_CONFIG=$(PREFIX)/bin/$(TARGET)-pkg-config \'; \
     echo 'exec $(PREFIX)/$(TARGET)/go/bin/go \'; \
     echo '"$$@"'; \
    ) \
             > '$(PREFIX)/bin/$(TARGET)-go'
    chmod 0755 '$(PREFIX)/bin/$(TARGET)-go'

    GOPATH=$(PWD)/plugins/go \
    '$(TARGET)-go' build \
        -o '$(PREFIX)/$(TARGET)/go/bin/test-go.exe' \
        mxe-test
endef

# -buildmode=shared not supported on windows
# See https://golang.org/s/execmodes
$(PKG)_BUILD_SHARED =
