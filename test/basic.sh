#!/usr/bin/env bats

setup() {
    load 'test_helper/utils'
    common_setup
}

R=test/resources

checkton_jq() {
    checkton.py "$@" | jq
}

@test "extract scripts from a Tekton YAML" {
    run checkton.py --scriptdir "$BATS_TEST_TMPDIR" "$R/tektontask/tektontask.yaml"
    run ls -1 "$BATS_TEST_TMPDIR/test/resources/tektontask/tektontask.yaml/"
    assert_output "$(printf '%d.sh\n' {0..4})"
    for i in {0..4}; do
        run cat "$BATS_TEST_TMPDIR/$R/tektontask/tektontask.yaml/${i}.sh"
        assert_output_file "$output" "$R/tektontask/extracted-scripts/${i}.sh"
    done
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
