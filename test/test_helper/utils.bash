common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    cd "$(dirname "$BATS_TEST_FILENAME")/.." || exit 1
    PATH="$PWD/src:$PATH"
}

assert_output_file() {
    local output=$1
    local expected_output_file=$2
    if [[ "${GENERATE_EXPECTED_OUTPUT:-}" == "true" ]]; then
        mkdir -p "$(dirname "$expected_output_file")"
        printf "%s\n" "$output" > "$expected_output_file"
    else
        assert_output "$(cat "$expected_output_file")"
    fi
}

test_human_readable_files() {
    local csgrep_input=$1
    local expected_files_dir=$2

    run csgrep --embed 4 <<< "$csgrep_input"
    assert_output_file "$output" "$expected_files_dir/csgrep.embed4.txt"

    run sarif-fmt --color never <<< "$csgrep_input"
    assert_output_file "$output" "$expected_files_dir/sarif-fmt.txt"
}
