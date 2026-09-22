PREVIOUS_TAG ?= $(shell git tag -l | tail -n 1)
TAG=v1.1.1

.PHONY: help
help:
	@echo 'Usage:'
	@echo '   make main-linux-amd64      Build static binary for linux/amd64 (requires upx)'
	@echo '   make main-linux-arm64      Build static binary for linux/arm64 (requires upx)'
	@echo '   make build                 Build all static binaries via Docker + bundle JS into dist/'
	@echo ''

GOLANG_VERSION := $(shell grep '^go ' go.mod | awk '{print $$2}')
COMMAND := "."

.PHONY: main-linux-amd64
main-linux-amd64:
	rm -f main-linux-amd64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -trimpath -buildvcs=false -installsuffix static -o "main-linux-amd64" $(COMMAND)
	upx -q -9 "main-linux-amd64"

.PHONY: main-linux-arm64
main-linux-arm64:
	rm -f main-linux-arm64
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -trimpath -buildvcs=false -installsuffix static -o "main-linux-arm64" $(COMMAND)
	upx -q -9 "main-linux-arm64"

.PHONY: build
build:
	docker run --rm \
		-v "$(PWD):/work" \
		-w /work \
		ubuntu:24.04 \
		bash -c "apt-get update -qq && \
		         apt-get install -y -qq upx curl make && \
		         curl -sL https://go.dev/dl/go$(GOLANG_VERSION).linux-amd64.tar.gz | tar -xz -C /usr/local && \
		         PATH=\$$PATH:/usr/local/go/bin make main-linux-amd64 main-linux-arm64"
	npm run build
	cp main-linux-amd64 main-linux-arm64 dist/

.PHONY: bump tag release upgrade

bump:
	gsed -i "s/$(PREVIOUS_TAG)/$(TAG)/g" README.md
	gsed -i "s/$(PREVIOUS_TAG)/$(TAG)/g" action.yml

tag: bump
	git tag -a $(TAG) -m "Release $(TAG)"
	git push origin $(TAG)

release: tag
	gh release create $(TAG) --generate-notes

upgrade:
	mise exec -- go get -u -t ./...
