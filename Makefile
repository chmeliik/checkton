IMAGE = localhost/checkton
INSTALL_NCURSES = false
GENERATE_EXPECTED_OUTPUT = false

.PHONY: build-image
build-image:
	podman build -t $(IMAGE) --build-arg INSTALL_NCURSES=$(INSTALL_NCURSES) .

.PHONY: test-with-prebuilt-image
test-with-prebuilt-image:
	podman run --rm -ti \
		-v "$(PWD):/code:z" \
		-e GENERATE_EXPECTED_OUTPUT=$(GENERATE_EXPECTED_OUTPUT) \
		-w /code $(IMAGE) \
	test/bats/bin/bats test/*.sh

.PHONY: test
test: INSTALL_NCURSES = true
test: build-image
test: test-with-prebuilt-image

.PHONY: generate-expected-test-output
generate-expected-test-output: GENERATE_EXPECTED_OUTPUT = true
generate-expected-test-output: test

.PHONY: generate-test-patches
generate-test-patches:
	test/resources/patches/generate.sh
