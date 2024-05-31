#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

BASE=${BASE:-$(git rev-parse main)}
HEAD=${HEAD:-$(git rev-parse HEAD)}

checkton() {
    "${SCRIPTDIR}/checkton.py" "$@"
}

cleanup() {
    rm -rf "$WORKDIR" || true
    git worktree remove "$WORKDIR/repo" || true
}

WORKDIR=$(mktemp -d --tmpdir "checkton-workdir.XXXXXX")
git worktree add -d "$WORKDIR/repo" "$BASE" >/dev/null
trap cleanup EXIT

mapfile -t changed_yaml_files < <(
    {
        git log --name-only --pretty=format: --diff-filter=d "${BASE}..${HEAD}"
        # handle uncommitted changes as well
        git diff --name-only --diff-filter=d
    } | awk '/\.yaml$|.yml$/' | sort -u
)

{
    echo "files to check:"
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
