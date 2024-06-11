#!/usr/bin/env bats
# vim: ft=bash

setup() {
    load 'test_helper/utils'
    common_setup
}

R=test/resources

checkton_jq() {
    checkton.py "$@" | jq
}

@test "checkton a Tekton YAML" {
    run checkton_jq "$R/tektontask/tektontask.yaml"
    assert_output_file "$output" "$R/tektontask/shellcheck.json"
}

@test "csgrep the results" {
    skip_unless_have_cmd csgrep
    run checkton_jq "$R/tektontask/tektontask.yaml"
    run csgrep --embed 4 <<< "$output"
    assert_output_file "$output" "$R/tektontask/csgrep.embed4.txt"
}

@test "sarif-fmt the results" {
    skip_unless_have_cmd csgrep sarif-fmt
    run checkton_jq "$R/tektontask/tektontask.yaml"
    run csgrep_sarif_fmt <<< "$output"
    assert_output_file "$output" "$R/tektontask/sarif-fmt.txt"
}
