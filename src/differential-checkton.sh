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

diff_args=(--name-status --diff-filter=d)

if [[ "${CHECKTON_FIND_RENAMES:-}" != "false" ]]; then
    diff_args+=("-M${CHECKTON_FIND_RENAMES:-}")
fi

if [[ "${CHECKTON_FIND_COPIES:-}" != "false" ]]; then
    diff_args+=("-C${CHECKTON_FIND_COPIES:-}")

    if [[ "${CHECKTON_FIND_COPIES_HARDER:-}" == "true" ]]; then
        diff_args+=(--find-copies-harder)
    fi
fi

files_to_check=$(
    {
        git log "${diff_args[@]}" --pretty=format: "${base}..${head}"
        # handle uncommitted changes as well
        git diff "${diff_args[@]}"
        git diff --staged "${diff_args[@]}"
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
renames=""

while read -r status name new_name; do
    if [[ -n "$new_name" ]]; then
        old_files+=("$name")
        new_files+=("$new_name")
        # git looks for renames by default, so filter them out if it's explicitly disabled
        # (this is not the case for copies)
        if [[ "$status" != *R* || "${CHECKTON_FIND_RENAMES:-}" != "false" ]]; then
            renames+=$(jq -n -c --arg old "$name" --arg new "$new_name" '{($old): $new}')
        fi
    else
        new_files+=("$name")
        # status includes A => the file didn't exist in the base ref
        if [[ "$status" != *A* ]]; then
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

if [[ "$renames" != "" ]]; then
    renames_json=$(jq -c -s 'reduce .[] as $kv ({}; . * $kv)' <<< "$renames")
    # For renamed/copied files, duplicate their comments (with the renamed filepath).
    # This allows csdiff to diff the reports as if the copied/renamed files had already
    # existed in the base ref (rather than treating such files as completely new).
    updated=$(
        jq < "$old_results" -c --argjson renames "$renames_json" '
            . as $original
            | .comments | map(select($renames[.file]) | .file |= $renames[.]) as $renamed_comments
            | $original
            | .comments += $renamed_comments
        '
    )
    printf "%s\n" "$updated" > "$old_results"
fi

csdiff "$old_results" "$new_results"
