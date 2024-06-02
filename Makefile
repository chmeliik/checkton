IMAGE = ghcr.io/chmeliik/checkton

.PHONY: build-image
build-image:
	podman build -t $(IMAGE):latest .

.PHONY: test
test: build-image
	podman run --rm -ti -v "$(PWD):/code:z" -w /code $(IMAGE):latest \
		test/bats/bin/bats test/*.bats
