#!/usr/bin/env bats

setup() {
    load 'test_helper/utils'
    common_setup

    if ! (git config --global user.name || git config --global user.email); then
        git config --global user.name "checkton-test"
        git config --global user.email "checkton-test@noreply.org"
    fi

    ORIGINAL_PATH=$PWD

    cp -r . "$BATS_TEST_TMPDIR/checkton"
    cd "$BATS_TEST_TMPDIR/checkton" || exit 1

    CHECKTON_DIFF_BASE=$(git rev-parse HEAD)
    export CHECKTON_DIFF_BASE
}

teardown() {
    cd "$ORIGINAL_PATH" || exit 1
    cp -r "$BATS_TEST_TMPDIR/checkton/test/resources/differential/." test/resources/differential
}

R=test/resources

differential_checkton() {
    rc=0
    differential-checkton.sh 2> "$BATS_TEST_TMPDIR/differential-checkton.err" || rc=$?
    if [ "$rc" -ne 0 ]; then
        cat "$BATS_TEST_TMPDIR/differential-checkton.err" >&2
    fi
    return $rc
}

test_differential_checkton() {
    local testcase_name=$1
    shift
    for patch in "$@"; do
        git am "$patch"
    done

    local expected_files_dir="$R/differential/$testcase_name"

    run differential_checkton
    local csdiff_output="$output"
    assert_output_file "$csdiff_output" "$expected_files_dir/csdiff.json"

    test_human_readable_files "$csdiff_output" "$expected_files_dir"
}

@test "report issues in new script" {
    test_differential_checkton new-script \
        "$R/patches/0001-Add-a-script-with-some-issues.patch"
}
