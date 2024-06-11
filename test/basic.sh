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
    local checkton_output="$output"
    assert_output_file "$checkton_output" "$R/tektontask/shellcheck.json"
    test_human_readable_files "$checkton_output" "$R/tektontask"
}
