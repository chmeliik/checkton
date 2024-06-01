#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

base=${CHECKTON_DIFF_BASE:-$(git rev-parse main)}
head=${CHECKTON_DIFF_HEAD:-$(git rev-parse HEAD)}

checkton() {
    "${SCRIPTDIR}/checkton.py" "$@"
}

cleanup() {
    rm -rf "$WORKDIR" || true
    git worktree remove "$WORKDIR/repo" 2>/dev/null || true
}

WORKDIR=$(mktemp -d --tmpdir "checkton-workdir.XXXXXX")
trap cleanup EXIT

files_to_check=$(
    {
        git log --name-status --pretty=format: --diff-filter=d "${base}..${head}"
        # handle uncommitted changes as well
        git diff --name-status --diff-filter=d
        git diff --staged --name-status --diff-filter=d
    } | awk '/\.ya?ml$/' | sort -u
)

{
    echo "Files to check:"
    if [[ -z "$files_to_check" ]]; then
        echo "  <none>"
        exit 0
    fi
    # shellcheck disable=SC2001
    sed -e '/^$/d' -e 's/^/  /' <<< "$files_to_check"
} >&2

old_files=()
new_files=()

while read -r status name new_name; do
    if [[ -n "$new_name" ]]; then
        old_files+=("$name")
        new_files+=("$new_name")
    else
        new_files+=("$name")
        # status includes A => the file is new
        if [[ ! "$status" == *A* ]]; then
            old_files+=("$name")
        fi
    fi
done <<< "$files_to_check"

old_results=$WORKDIR/old.err
new_results=$WORKDIR/new.err

if [[ ${#old_files[@]} -gt 0 ]]; then
    if ! git worktree add -d "$WORKDIR/repo" "$base" >/dev/null 2>"$WORKDIR/err"; then
        printf "checking files at base ref: failed to create git worktree: %s\n" \
            "$(cat "$WORKDIR/err")" >&2
        exit 1
    fi
    (cd "$WORKDIR/repo" && checkton "${old_files[@]}" > "$old_results")
else
    touch "$old_results"
fi

checkton "${new_files[@]}" > "$new_results"

csdiff "$old_results" "$new_results"
