#!/usr/bin/env bats
# vim: ft=bash

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    cd "$(dirname "$BATS_TEST_FILENAME")/.." || exit 1
    PATH="$PWD/src:$PATH"
}

R=test/resources

checkton_jq() {
    checkton.py "$@" | jq
}

csgrep_sarif_fmt() {
    csgrep --mode=sarif | sarif-fmt --color never
}

skip_unless_have_cmd() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null || skip "missing command: $cmd"
    done
}

assert_output_file() {
    local expected_output_file=$1
    if [[ "${GENERATE_EXPECTED_OUTPUT:-}" == "true" ]]; then
        mkdir -p "$(dirname "$expected_output_file")"
        printf "%s\n" "$output" > "$expected_output_file"
    else
        assert_output "$(cat "$expected_output_file")"
    fi
}

@test "checkton a Tekton YAML" {
    run checkton_jq "$R/tektontask/tektontask.yaml"
    assert_output_file "$R/tektontask/shellcheck.json"
}

@test "csgrep the results" {
    skip_unless_have_cmd csgrep
    run csgrep --embed 4 < "$R/tektontask/shellcheck.json"
    assert_output_file "$R/tektontask/csgrep.embed4.txt"
}

@test "sarif-fmt the results" {
    skip_unless_have_cmd csgrep sarif-fmt
    run csgrep_sarif_fmt < "$R/tektontask/shellcheck.json"
    assert_output_file "$R/tektontask/sarif-fmt.txt"
}
