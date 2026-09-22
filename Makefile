PREVIOUS_TAG ?= $(shell git tag -l | tail -n 1)
TAG=v1.1.1

.PHONY: help
help:
	@echo 'Usage:'
	@echo '   make main-linux-amd64      Build static binary for linux/amd64'
	@echo '   make main-linux-arm64      Build static binary for linux/arm64'
	@echo '   make build                 Build all static binaries + bundle JS into dist/'
	@echo ''

COMMAND := "."

# Pinned so the binaries are byte-for-byte reproducible on any host. Anything
# recorded in .go.buildinfo (GOEXPERIMENT, GOFLAGS, GOAMD64/GOARM64) must not be
# inherited from the developer's environment, or `check_dist` sees a diff.
GOENV := CGO_ENABLED=0 GOEXPERIMENT= GOFLAGS= GOOS=linux

.PHONY: main-linux-amd64
main-linux-amd64:
	rm -f main-linux-amd64
	$(GOENV) GOARCH=amd64 GOAMD64=v1 go build -ldflags="-s -w" -trimpath -buildvcs=false -installsuffix static -o "main-linux-amd64" $(COMMAND)

.PHONY: main-linux-arm64
main-linux-arm64:
	rm -f main-linux-arm64
	$(GOENV) GOARCH=arm64 GOARM64=v8.0 go build -ldflags="-s -w" -trimpath -buildvcs=false -installsuffix static -o "main-linux-arm64" $(COMMAND)

.PHONY: build
build: main-linux-amd64 main-linux-arm64
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
