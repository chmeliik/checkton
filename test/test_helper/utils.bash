common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    cd "$(dirname "$BATS_TEST_FILENAME")/.." || exit 1
    PATH="$PWD/src:$PATH"
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
    local output=$1
    local expected_output_file=$2
    if [[ "${GENERATE_EXPECTED_OUTPUT:-}" == "true" ]]; then
        mkdir -p "$(dirname "$expected_output_file")"
        printf "%s\n" "$output" > "$expected_output_file"
    else
        assert_output "$(cat "$expected_output_file")"
    fi
}
