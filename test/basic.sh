#!/usr/bin/env bats

setup() {
    load 'test_helper/utils'
    common_setup
}

R=test/resources

checkton_jq() {
    checkton.py "$@" | jq
}

test_basic_checkton() {
    local file_to_check=$1

    run checkton_jq --scriptdir "$BATS_TEST_TMPDIR" "$file_to_check"
    local checkton_output="$output"
    assert_output_file "$checkton_output" "${file_to_check}-outputs/shellcheck.json"
    test_human_readable_files "$checkton_output" "${file_to_check}-outputs"

    find "$BATS_TEST_TMPDIR/$file_to_check/" -type f | while read -r script_file; do
        run cat "$script_file"
        assert_output_file "$output" "${file_to_check}-scripts/$(basename "$script_file")"
    done

}

@test "checkton a Tekton YAML" {
    test_basic_checkton "$R/tektontask/tektontask.yaml"
}
