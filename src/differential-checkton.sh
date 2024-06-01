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
    git worktree remove "$WORKDIR/repo" || true
}

WORKDIR=$(mktemp -d --tmpdir "checkton-workdir.XXXXXX")
trap cleanup EXIT

if ! git worktree add -d "$WORKDIR/repo" "$base" >/dev/null 2>"$WORKDIR/err"; then
    cat "$WORKDIR/err" >&2
    exit 1
fi

mapfile -t changed_yaml_files < <(
    {
        git log --name-only --pretty=format: --diff-filter=d "${base}..${head}"
        # handle uncommitted changes as well
        git diff --name-only --diff-filter=d
    } | awk '/\.yaml$|.yml$/' | sort -u
)

{
    echo "Files to check:"
    if [[ ${#changed_yaml_files[@]} -eq 0 ]]; then
        echo "  <none>"
        exit 0
    fi
    printf "  %s\n" "${changed_yaml_files[@]}"
} >&2

old_results=$WORKDIR/old.err
new_results=$WORKDIR/new.err

(cd "$WORKDIR/repo" && checkton "${changed_yaml_files[@]}" > "$old_results")
checkton "${changed_yaml_files[@]}" > "$new_results"

csdiff "$old_results" "$new_results"
