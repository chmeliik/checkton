IMAGE = ghcr.io/chmeliik/checkton
GENERATE_EXPECTED_OUTPUT = false

.PHONY: build-image
build-image:
	podman build -t $(IMAGE):latest .

.PHONY: test
test: build-image
	podman run --rm -ti \
		-v "$(PWD):/code:z" \
		-e GENERATE_EXPECTED_OUTPUT=$(GENERATE_EXPECTED_OUTPUT) \
		-w /code $(IMAGE):latest \
	test/bats/bin/bats test/*.sh

.PHONY: generate-expected-test-output
generate-expected-test-output: GENERATE_EXPECTED_OUTPUT = true
generate-expected-test-output: test

.PHONY: generate-test-patches
generate-test-patches:
	test/resources/patches/generate.sh
